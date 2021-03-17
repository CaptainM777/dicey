# Crystal: Moderation - Write what the crystal does here.

require 'rufus-scheduler'

module Bot::Moderation
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Constants
  include Bot::Models

  muted_role_id = ENV['BOT_NAME'] == 'thunder' ? 808009631451709510 : 668616677306531870
  mod_log = Bot::BOT.channel(MOD_LOG_ID)
  moderation_commands = HELP_COMMAND["moderation"]

  class << self
    def valid_user?(user, channel)
      return Bot::BOT.get_member(user) if Bot::BOT.get_member(user)
      channel.send_temporary_message("**The user you provided is invalid! Make sure you give a valid user ID or user mention.**", 10)
      nil
    end

    def send_dm(user, message)
      dm_sent = false
      begin
        user.dm(message)
      rescue Discordrb::Errors::NoPermission
      else
        dm_sent = true
      end
      dm_sent
    end

    # Takes the given time string argument, in a format similar to '5d2h15m45s' and returns its representation in
    # a number of seconds.
    # @param  [String]  str the string to parse into a number of seconds
    # @return [Integer]     the number of seconds the given string is equal to, or 0 if it cannot be parsed properly
    def parse_time(str)
      seconds = 0
      str.scan(/\d+ *[Dd]/).each { |m| seconds += (m.to_i * 24 * 60 * 60) }
      str.scan(/\d+ *[Hh]/).each { |m| seconds += (m.to_i * 60 * 60) }
      str.scan(/\d+ *[Mm]/).each { |m| seconds += (m.to_i * 60) }
      str.scan(/\d+ *[Ss]/).each { |m| seconds += (m.to_i) }
      seconds
    end

    # Takes the given number of seconds and converts into a string that describes its length (i.e. 3 hours,
    # 4 minutes and 5 seconds, etc.)
    # @param  [Integer] secs the number of seconds to convert
    # @return [String]       the length of time described
    def time_string(secs)
      dhms = ([secs / 86400] + Time.at(secs).utc.strftime('%H|%M|%S').split("|").map(&:to_i)).zip(['day', 'hour', 'minute', 'second'])
      dhms.shift while dhms[0][0] == 0
      dhms.pop while dhms[-1][0] == 0
      dhms.map! { |(v, s)| "#{v} #{s}#{v == 1 ? nil : 's'}" }
      return dhms[0] if dhms.size == 1
      "#{dhms[0..-2].join(', ')} and #{dhms[-1]}"
    end
  end
   
  command :warn, allowed_roles: STAFF_ROLES, 
          min_args: 2, usage: moderation_commands["warn"]["usage"] do |event, user, *reason|
    break unless (user = valid_user?(user, event.channel))
    dm_sent = send_dm(user, "**⚠ You've received a warning from the server staff.**\n**Reason:** #{reason.join(" ")}")
    if !dm_sent
      event << "A DM couldn't be sent to this user because they either have DM's turned off for this server or have the bot blocked. " + 
               "A warning will still be logged to the mod log channel."
    end
    ModerationLogger.set_context(user, reason, mod: event.user, dm_sent: dm_sent)
    ModerationLogger.log_warning(user.id)
    event << "**Warned #{user.distinct}.**"
  end

  command :mute, allowed_roles: STAFF_ROLES, min_args: 2,
          usage: moderation_commands["mute"]["usage"] do |event, *args|
    break unless (user = valid_user?(args[0], event.channel))
    length = parse_time(args[1])
    reason = length == 0 ? args[1..-1].join(" ") : args[2..-1].join(" ")

    if reason.empty?
      event.send_temporary_message("**You are missing a mute reason!**", 10)
      break
    end

    dm_sent = send_dm(user, "**🔇 You've been muted for #{length == 0 ? "an indefinite amount of time" : time_string(length)}.**\n**Reason:** #{reason}")
    if !dm_sent
      event << "A DM couldn't be sent to this user because they either have DM's turned off for this server or have the bot blocked. " + 
               "The user will still be muted and this mute will be logged to the mod log channel."
    end

    user.add_role(muted_role_id)
    if length == 0
      MutedUser.create(user_id: user.id, reason: reason)    
    else
      job_id = SCHEDULER.in length do
        user.remove_role(muted_role_id)
        MutedUser[user.id].delete
        ModerationLogger.log_unmute(user.id)
      end

      MutedUser.create(
        user_id: user.id,
        job_id: job_id, 
        mute_start: Time.now, 
        mute_end: Time.now + length,
        reason: reason
      )
    end

    ModerationLogger.set_context(user, reason, mod: event.user, dm_sent: dm_sent, 
                                 length: length == 0 ? "Indefinite" : time_string(length))
    ModerationLogger.log_mute(user.id)
    event << "**Muted #{user.distinct}.**"
  end

  command :unmute, allowed_roles: STAFF_ROLES, min_args: 1,
          usage: moderation_commands["unmute"]["usage"] do |event, user|
    break unless (user = valid_user?(user, event.channel))
    muted_user = MutedUser[user.id]
    if !muted_user
      event.send_temporary_message("**The user you're trying to unmute isn't currently muted!**", 10)
      break
    end

    dm_sent = send_dm(user, "**You have been unmuted by a staff member.**")
    if !dm_sent
      event << "A DM couldn't be sent to this user because they either have DM's turned off for this server or have the bot blocked."
    end

    user.remove_role(muted_role_id)
    SCHEDULER.end_job(muted_user.job_id) if muted_user.job_id
    ModerationLogger.log_unmute(muted_user.user_id, moderator=event.user)
    muted_user.delete
    event << "**#{user.distinct} has been unmuted.**"
  end

  command :getmute, allowed_roles: STAFF_ROLES, min_args: 1,
          usage: moderation_commands["getmute"]["usage"] do |event, user|
    break unless (user = valid_user?(user, event.channel))
    muted_user = MutedUser[user.id]
    if !muted_user
      event.send_temporary_message("**This user is not currently muted!**", 10)
      break
    end

    event.channel.send_embed do |embed|
      embed.author = {
        name: user.distinct,
        icon_url: user.avatar_url
      }
      embed.add_field(name: "Reason", value: muted_user.reason)
      embed.add_field(name: "Length", value: time_string(muted_user.mute_length.to_i))
      embed.add_field(name: "Time Left", value: time_string(muted_user.time_left.to_i))
      embed.footer = {
        text: "User ID: #{muted_user.user_id} | #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}"
      }
    end
  end
end