defmodule Beabadoobee.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    create table(:guilds, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :meow_channel_id, :bigint
    end

    create table(:lastfm, primary_key: false) do
      add :user_id, :bigint, primary_key: true
      add :username, :string
    end

    create table(:members, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :user_id, :bigint, primary_key: true
      add :xp, :bigint
      add :meow_count, :bigint
    end

    create table(:role_rewards, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :role_id, :bigint, null: false
      add :requirement, :bigint, null: false
    end

  end
end
