# This file contains the schema for the database.
# Under most circumstances, you shouldn't need to run this file directly.
require 'sequel'

module Schema
  Sequel.sqlite(ENV['DB_PATH']) do |db|
    db.create_table?(:muted_users) do
      primary_key :user_id
      String :job_id, :size=>255
      DateTime :mute_start
      DateTime :mute_end
      String :reason, :size=>255
    end
  end
end