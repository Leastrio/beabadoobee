defmodule Beabadoobee.Repo.Migrations.AddWebhook do
  use Ecto.Migration

  def change do
    alter table("guilds") do
      add :webhook_id, :bigint
      add :webhook_token, :string
    end
  end
end
