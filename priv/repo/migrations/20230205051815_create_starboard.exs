defmodule Beabadoobee.Repo.Migrations.CreateStarboard do
  use Ecto.Migration

  def change do
    create table(:stars, primary_key: false) do
      add :msg_id, :bigint, primary_key: true
      add :guild_id, :bigint
      add :channel_id, :bigint
      add :starboard_msg_id, :bigint
    end
  end
end
