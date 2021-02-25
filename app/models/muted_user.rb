# Model: MutedUser
class Bot::Models::MutedUser < Sequel::Model
  # include Constants
  unrestrict_primary_key

  def time_left
    mute_end - Time.now
  end
end