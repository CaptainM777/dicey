# Migration: AddMutedUsersTableToDatabase
Sequel.migration do
  change do
    create_table(:muted_users) do
      Integer :user_id, primary_key: true
      String :job_id, default: nil
      Time :mute_start, default: nil 
      Time :mute_end, default: nil
      String :reason
    end
  end
end