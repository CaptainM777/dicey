# Crystal: VoiceChats - Write what the crystal does here.
module Bot::VoiceChats
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer

  # Voice => Text
  channels = { 
    807690259847577681 => 807695138335621151 # voice
  }
  
  voice_state_update do |event|
    # Skips if the voice state update is a mute/deafen
    next if event.channel == event.old_channel

    # User leaves VC or changes VC's
    if !(event.old_channel.nil?) && channels.include?(event.old_channel.id)
      old_text_channel = Bot::BOT.channel(channels[event.old_channel.id])
      old_text_channel.delete_overwrite(event.user.id)
    end

    # User just joined VC or changes VC's
    if !(event.channel.nil?) && channels.include?(event.channel.id)
      text_channel = Bot::BOT.channel(channels[event.channel.id])
      if !(text_channel.nil?)
        text_channel.define_overwrite(event.user, 1024, 0) # Gives read perms for the text channel
        text_channel.send_temporary_message("#{event.user.mention}, you have gained access to <##{text_channel.id}>.", 5)
      end
    end
  end
end