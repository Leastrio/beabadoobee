defmodule Beabadoobee.Repo.Migrations.CreateGuilds do
  use Ecto.Migration

  def change do
    create table(:guilds, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :meow_channel_id, :bigint
    end
  end
end
