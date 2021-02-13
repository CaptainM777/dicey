# Crystal: Fun - Contains, well...fun commands.
module Bot::Fun
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  
  command :say, aliases: [:s], usage: "-say [channel] [message]" do |event, *args|
    break unless event.user.has_permission?(:mod) && !args.empty?
    channel = Bot::BOT.get_channel(args[0])
    if channel.nil?
      event.respond(args[0..-1].join(" "))
    else
      channel.send(args[1..-1].join(" "))
    end
  end
end