# Crystal: Help - Write what the crystal does here.
module Bot::Help
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Constants
  
  master_list_description = HELP_COMMAND["master-list-description"]
  specific_command_footer = HELP_COMMAND["specific-command-footer"]

  HELP_COMMAND.delete("master-list-description")
  HELP_COMMAND.delete("specific-command-footer")

  def self.has_one_user_command?(commands_hash)
    commands_hash.each_value do |info|
      return true unless info["mod_command?"]
    end
    false
  end

  command :help do |event, *args|
    type = args.join(" ").empty? ? "master" : args.join(" ")

    if type == "master"
      fields = []
      HELP_COMMAND.each do |category, commands|
        category = "**#{category.split("-").map!(&:capitalize).join(" ")}**"
        field = { name: "", value: [] }

        if event.user.has_permission?(:mod)
          field[:name] = category
          commands.each_value{ |info| field[:value] << info["overview"] }
        else
          if has_one_user_command?(commands)
            field[:name] = category
            user_commands = commands.select{ |command, info| !info["mod_command?"] }
            user_commands.each_value{ |info| field[:value] << info["overview"] }
          end
        end

        field[:value] = field[:value].join("\n")
        fields << field
      end

      fields.reject!{ |hash| hash[:name].empty? && hash[:value].empty? }

      event.send_embed do |embed|
        embed.title = "__Command List #{event.user.has_permission?(:mod) ? "(moderator)" : "(user)"}__"
        embed.description = master_list_description
        fields.each{ |field| embed.add_field(name: field[:name], value: field[:value]) }
        embed.color = 0xFFD700
      end
    else
      type = type.downcase
      HELP_COMMAND.each_value do |commands|
        command = commands.select{ |command, info| command == type }
        next if command.empty? || (!event.user.has_permission?(:mod) && command[type]["mod_command?"]) || !command[type].member?("description")
        event.send_embed do |embed|
          embed.title = "Help: -#{type}"
          embed.description = command[type]["description"]
          embed.footer = { text: specific_command_footer }
          embed.color = 0xFFD700
        end
        break
      end
      nil # This is here to prevent implicit return
    end
  end
end