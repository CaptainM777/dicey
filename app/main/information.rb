# Crystal: Information - Contains commands that give information about various things.
module Bot::Information
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  
  # Gives a link that provides information on how to get a user, server, and message ID
  command :id do |event|
    event << "**How to get a user, server, or message ID:** "
    event << "https://support.discord.com/hc/en-us/articles/206346498-Where-can-I-find-my-User-Server-Message-ID-"
  end
end