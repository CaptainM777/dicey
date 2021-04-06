# Crystal: Moderation::Mutes - Contains all commands and functionalities related to mutes.

require 'rufus-scheduler'
require_relative 'utilities.rb'

module Bot::Moderation::Mutes
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utilities
  include Constants
  include Bot::Models
  
  command :mute, allowed_roles: STAFF_ROLES, min_args: 2,
          usage: MODERATION_COMMANDS["mute"]["usage"] do |event, *args|
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

    user.add_role(MUTED_ROLE_ID)
    if length == 0
      MutedUser.create(user_id: user.id, reason: reason)    
    else
      job_id = SCHEDULER.in length do
        user.remove_role(MUTED_ROLE_ID)
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
          usage: MODERATION_COMMANDS["unmute"]["usage"] do |event, user|
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

    user.remove_role(MUTED_ROLE_ID)
    SCHEDULER.end_job(muted_user.job_id) if muted_user.job_id
    ModerationLogger.log_unmute(muted_user.user_id, moderator=event.user)
    muted_user.delete
    event << "**#{user.distinct} has been unmuted.**"
  end

  command :getmute, allowed_roles: STAFF_ROLES, min_args: 1,
          usage: MODERATION_COMMANDS["getmute"]["usage"] do |event, user|
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

   # Commands for my use only

   command :jobexists, min_args: 1 do |event, user|
    break unless (user = valid_user?(user, event.channel)) && event.user.has_permission?(:cap)
    muted_user = MutedUser[user.id]
    if muted_user.nil?
      event << "**This user is not currently muted.**"
      break
    end
    job = SCHEDULER.job(muted_user.job_id)
    if job.nil?
      event << "**There is no job scheduled for #{user.mention}.**"
    else
      event << "**There is a job scheduled for #{user.mention}.**"
    end
  end
end