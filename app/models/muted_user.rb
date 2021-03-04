# Model: MutedUser
class Bot::Models::MutedUser < Sequel::Model
  unrestrict_primary_key

  def time_left
    mute_end - Time.now
  end
end