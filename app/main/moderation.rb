# Crystal: Moderation - Write what the crystal does here.

require 'rufus-scheduler'

module Bot::Moderation
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Constants

  MOD_LOG ||= Bot::BOT.channel(MOD_LOG_ID)

  def self.valid_user?(user, channel)
    return Bot::BOT.get_user(user) if Bot::BOT.get_user(user)
    channel.send_temporary_message("**The user you provided is invalid! Make sure you give a valid user ID or user mention.**", 10)
  end
  
  command :warn, allowed_roles: STAFF_ROLES, 
          min_args: 2, usage: HELP_COMMAND["moderation"]["warn"]["usage"] do |event, user, *reason|
    break unless (user = valid_user?(user, event.channel))
    dm_sent = false
    begin
      user.dm("**⚠ You've received a warning from the server staff.**\n**Reason:** #{reason.join(" ")}")
    rescue Discordrb::Errors::NoPermission
      if user.on(event.server).nil?
        event << "A DM couldn't be sent to this user because they left the server. This warning will not be logged."
        break
      end
      event << "A DM couldn't be sent to this user because they either have DM's turned off for this server or have the bot blocked. " + 
               "A warning will still be logged to the mod log channel."
    else
      event << "**Sent warning to #{user.distinct}.**"
      dm_sent = true
    end

    MOD_LOG.send_embed do |embed|
      embed.author = {
        name: "WARNING | #{user.name} (#{user.distinct})",
        icon_url: user.avatar_url
      }
      embed.description = "**⚠ #{user.mention} was given a warning by #{event.user.mention} (#{event.user.distinct})**"
      embed.add_field(name: "Reason", value: reason.join(" "))
      embed.add_field(name: "Additional Information", value: "A DM couldn't be sent to this user.") unless dm_sent
      embed.footer = { 
        text: "User ID: #{user.id} | Staff ID: #{event.user.id} • #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p UTC")}" 
      }
      embed.color = 0xFFD700
    end
  end
end