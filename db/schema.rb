# This file contains the schema for the database.
# Under most circumstances, you shouldn't need to run this file directly.
require 'sequel'

module Schema
  Sequel.sqlite(ENV['DB_PATH']) do |db|
    db.create_table?(:muted_users) do
      primary_key :user_id
      DateTime :mute_start, :null=>false
      DateTime :mute_end, :null=>false
      String :reason, :size=>255
    end
  end
end