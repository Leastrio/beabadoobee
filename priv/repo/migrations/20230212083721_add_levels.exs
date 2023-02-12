defmodule Beabadoobee.Repo.Migrations.AddLevels do
  use Ecto.Migration

  def change do
    alter table("guilds") do
      add :level_up_channel_id, :bigint
    end

    create table(:levels, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :user_id, :bigint, primary_key: true
      add :xp, :integer
    end
  end
end
