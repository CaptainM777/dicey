require 'rufus-scheduler'

module Constants
  def self.determine_id(tox_id, personal_id)
    ENV['BOT_NAME'] == "thunder" ? tox_id : personal_id
  end

  CAP_ID = 260600155630338048
  MOD_ROLE_ID ||= determine_id(807694130448302080, 665696287772901416)
  DB = Bot::DB
  SCHEDULER = Rufus::Scheduler.new
end