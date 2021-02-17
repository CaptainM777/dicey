# Crystal: Moderation - Write what the crystal does here.
module Bot::Moderation
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Constants

  MOD_LOG ||= Bot::BOT.channel(MOD_LOG_ID)

  def self.valid_user?(user, channel)
    return Bot::BOT.get_user(user) if Bot::BOT.get_user(user)
    channel.send_temporary_message("**The user you provided is invalid! Make sure you give a valid user ID or user mention.**", 15)
  end
  
  command :warn do |event, user="", *reason|
    break unless event.user.has_permission?(:mod) && 
                 (user = valid_user?(user, event.channel)) &&
                 !reason.empty?
    # To-Do Task: account for scenarios where the bot attempts to DM someone not on the server
    user.dm("**⚠ You've received a warning from the server staff.**\n**Reason:** #{reason.join(" ")}")
    MOD_LOG.send_embed do |embed|
      embed.author = {
        name: "WARNING | #{user.name} (#{user.distinct})",
        icon_url: user.avatar_url
      }
      embed.description = "**⚠ #{user.mention} was given a warning by #{event.user.mention} (#{event.user.distinct})**"
      embed.add_field(name: "Reason", value: reason.join(" "))
      embed.footer = { 
        text: "User ID: #{user.id} | Staff ID: #{event.user.id} • #{Time.new.utc.strftime("%Y-%m-%d at %l:%M %p")}" 
      }
      embed.color = 0xFFD700
      event << "**Sent warning to #{user.distinct}.**"
    end
  end
end