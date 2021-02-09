# Required gems for the bot initialization
require 'discordrb'
require 'sequel'
require 'yaml'

# The main bot; all individual crystals will be submodules of this, giving them
# access to the bot object as a constant, Bot::BOT
module Bot
  # Formats and sends an error message and then exits the program
  def self.send_error_message(message)
    puts "ERROR: #{message}. Exiting..."
    exit(false)
  end

  puts '==GEODE V2: A (Modified) Clunky Modular Ruby Bot Framework With A Database=='

  # Sets path to the data folder as environment variable
  ENV['DATA_PATH'] = File.expand_path('data')

  # Converts the 'config_files' path into an absolute path
  config_folder_path = File.expand_path("config_files")

  puts "Loading bot settings..."

  # Loads the master config file and converts the keys to symbols so that they can be properly parsed by the CommandBot constructor
  config = YAML.load_file("#{config_folder_path}/config.yml").transform_keys(&:to_sym)

  send_error_message("The 'bot' field in 'config.yml' hasn't been filled out") if config[:bot].nil?

  # Converts the values for 'log_mode' and 'type' to symbols so that they can be properly parsed by the CommandBot constructor
  config[:log_mode] = config[:log_mode].to_sym
  config[:type] = config[:type].to_sym

  # Removes any fields from the config hash that were left blank in 'config.yml'
  config.reject!{ |k,v| v.nil? }

  # Loads the bot settings file
  bots = YAML.load_file("#{config_folder_path}/bots.json")

  # Loads the token and prefix from 'bots.json' and creates entries for them in the config hash
  if bots.has_key?(config[:bot])
    bot_name = config[:bot]
    config[:token] = bots[bot_name]["token"] if bots[bot_name]["token"]
    config[:prefix] = bots[bot_name]["prefix"] if bots[bot_name]["prefix"]

    unless config[:token] && config[:prefix]
      send_error_message("The bot you want to use (#{bot_name}) is missing either a 'token' or a 'prefix' field in the 'bots.json' file")
    end
  else
    send_error_message("The bot name given in 'config.yml' is not in the 'bots.json' file")
  end

  puts "Done."

  # Deletes the 'bot' and 'game' keys so it doesn't get parsed by the CommandBot
  config.delete(:bot)
  game = config[:game]
  config.delete(:game)

  puts 'Initializing the bot object...'

  # Creates the bot object using the config attributes; this is a constant
  # in order to make it accessible by crystals
  BOT = Discordrb::Commands::CommandBot.new(config.to_h)

  # Sets the bot's playing game unless one wasn't provided in 'config.yml'
  BOT.ready { BOT.game = game } unless game.nil?

  puts 'Done.'

  puts 'Loading application data (database, models, etc.)...'

  # Database constant
  DB = Sequel.sqlite(ENV['DB_PATH'])

  # Load model classes and print to console
  Models = Module.new
  Dir['app/models/*.rb'].each do |path|
    load path
    if (filename = File.basename(path, '.*')).end_with?('_singleton')
      puts "+ Loaded singleton model class #{filename[0..-11].camelize}"
    else
      puts "+ Loaded model class #{filename.camelize}"
    end
  end

  puts 'Done.'

  puts 'Loading additional scripts in lib directory...'

  # Loads the constants file first so files in the lib directory can use it
  require './lib/constants.rb'
  puts "+ Loaded file lib/constants.rb"

  # Loads files from lib directory in parent
  Dir['./lib/**/*.rb'].sort.each do |path|
    next if path == "./lib/constants.rb"
    require path
    puts "+ Loaded file #{path[2..-1]}"
  end

  puts 'Done.'

  # Load all crystals, preloading their modules if they are nested within subfolders
  ENV['CRYSTALS_TO_LOAD'].split(',').each do |path|
    crystal_name = path.camelize.split('::')[2..-1].join('::').sub('.rb', '')
    parent_module = crystal_name.split('::')[0..-2].reduce(self) do |memo, name|
      if memo.const_defined? name
        memo.const_get name
      else
        submodule = Module.new
        memo.const_set(name, submodule)
        submodule
      end
    end
    load path
    BOT.include! self.const_get(crystal_name)
    puts "+ Loaded crystal #{crystal_name}"
  end

  puts "Starting bot with logging mode #{config[:log_mode]}..."
  BOT.ready { puts 'Bot started!' }

  # After loading all desired crystals, run the bot
  BOT.run
end
