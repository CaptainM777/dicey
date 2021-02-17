# Crystal: Help - Write what the crystal does here.
module Bot::Help
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  
  help_command = YAML.load_file 'help.yml'

  master_list_description = help_command["master-list-description"]
  specific_command_footer = help_command["specific-command-footer"]

  help_command.delete("master-list-description")
  help_command.delete("specific-command-footer")

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
      help_command.each do |category, commands|
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
      help_command.each_value do |commands|
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