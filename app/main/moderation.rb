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
    def parse_time(str, channel)
      seconds = 0
      str.scan(/\d+ *[Dd]/).each { |m| seconds += (m.to_i * 24 * 60 * 60) }
      str.scan(/\d+ *[Hh]/).each { |m| seconds += (m.to_i * 60 * 60) }
      str.scan(/\d+ *[Mm]/).each { |m| seconds += (m.to_i * 60) }
      str.scan(/\d+ *[Ss]/).each { |m| seconds += (m.to_i) }
      return seconds if seconds != 0
      channel.send_temporary_message("**The length you provided is invalid! Make sure you give a valid time length, like 3h (3 hours) or 5d (5 days).**", 10)
      nil
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

    def unmute_embed(user, reason, length)
      Discordrb::Webhooks::Embed.new(
        author: {
          name: "UNMUTE | #{user.distinct}",
          icon_url: user.avatar_url
        },
        description: "**#{user.mention} was unmuted.**",
        fields: [
          {
            name: "Mute Length",
            value: time_string(length)
          },
          {
            name: "Reason for Mute",
            value: reason.join(" ")
          }
        ],
        footer: { 
          text: "User ID: #{user.id} | #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}" 
        },
        color: 0xFFD700
      )
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
    ModerationLogger.set_context(user, event.user, reason, dm_sent)
    ModerationLogger.log_warning(user.id)
    event << "**Warned #{user.distinct}.**" if dm_sent
  end

  command :mute, allowed_roles: STAFF_ROLES,
          min_args: 3, usage: moderation_commands["mute"]["usage"] do |event, user, length, *reason|
    break unless (user = valid_user?(user, event.channel)) && (length = parse_time(length, event.channel))
    dm_sent = send_dm(user, "**🔇 You've been muted for #{time_string(length)}.**\n**Reason:** #{reason.join(" ")}")
    if !dm_sent
      event << "A DM couldn't be sent to this user because they either have DM's turned off for this server or have the bot blocked. " + 
               "The user will still be muted and this mute will be logged to the mod log channel."
    end

    user.add_role(muted_role_id)
    MutedUser.create(
      user_id: user.id, 
      mute_start: Time.now, 
      mute_end: Time.now + length,
      reason: reason.join(" ")
    )

    SCHEDULER.in length do
      user.remove_role(muted_role_id)
      MutedUser[user.id].delete
      ModerationLogger.set_context(user, event.user, reason, dm_sent, length: time_string(length))
      ModerationLogger.log_unmute(user.id)
    end

    ModerationLogger.set_context(user, event.user, reason, dm_sent, length: time_string(length))
    ModerationLogger.log_mute(user.id)
    event << "**Muted #{user.distinct}.**" if dm_sent
  end
end