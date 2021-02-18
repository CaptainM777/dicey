require 'rufus-scheduler'

module Constants
  def self.determine_id(tox_id, personal_id)
    ENV['BOT_NAME'] == "thunder" ? tox_id : personal_id
  end

  # Roles
  ADMIN_ROLE_ID ||= determine_id(807691115049648158, 665696338536824848)
  MOD_ROLE_ID ||= determine_id(807694130448302080, 665696287772901416)
  STAFF_ROLES ||= [ADMIN_ROLE_ID, MOD_ROLE_ID]

  # Channels
  MOD_LOG_ID ||= determine_id(808921994540089385, 651969052155183128)

  # Other constants
  CAP_ID = 260600155630338048
  DB = Bot::DB
  SCHEDULER = Rufus::Scheduler.new
  HELP_COMMAND ||= YAML.load_file 'help.yml'
end