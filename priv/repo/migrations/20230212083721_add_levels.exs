defmodule Beabadoobee.Repo.Migrations.AddLevels do
  use Ecto.Migration

  def change do
    alter table("guilds") do
      add :level_up_channel_id, :bigint
    end
  end
end
