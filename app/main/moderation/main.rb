# Crystal: Moderation - Write what the crystal does here.

require_relative 'utilities.rb'

module Bot::Moderation::Main
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utilities
  include Constants
  include Bot::Models
   
  command :warn, allowed_roles: STAFF_ROLES, 
          min_args: 2, usage: MODERATION_COMMANDS["warn"]["usage"] do |event, user, *reason|
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
end