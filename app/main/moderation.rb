# Crystal: Moderation - Write what the crystal does here.
module Bot::Moderation
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Constants

  MOD_LOG ||= Bot::BOT.channel(MOD_LOG_ID)
  # DM_MESSAGES = {
  #   warning: "**⚠ You've received a warning from the server staff.**",
  #   mute: "**🔇 You've been muted by the server staff.**",
  #   perma_ban: "**You've been permanently banned from the server.**",
  #   temp_ban: "**You've been temporarily banned from the server.**"
  # }

  # # Module methods
  # class << self
  #   def user_on_server?(user)
  #     user.on(event.server)
  #   end

  #   def dm_user(user, command_type, )
  #     begin
  #       user
  #   end
  # end

  def self.valid_user?(user, channel)
    return Bot::BOT.get_user(user) if Bot::BOT.get_user(user)
    channel.send_temporary_message("**The user you provided is invalid! Make sure you give a valid user ID or user mention.**", 15)
  end
  
  command :warn do |event, user="", *reason|
    break unless event.user.has_permission?(:mod) && 
                 (user = valid_user?(user, event.channel)) &&
                 !reason.empty?
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