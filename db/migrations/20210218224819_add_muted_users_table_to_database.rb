# Migration: AddMutedUsersTableToDatabase
Sequel.migration do
  change do
    create_table(:muted_users) do
      Integer :user_id, primary_key: true
      Time :mute_start, null: false
      Time :mute_end, null: false
      String :reason
    end
  end
end