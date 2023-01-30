defmodule Beabadoobee.Repo.Migrations.CreateLastfm do
  use Ecto.Migration

  def change do
    create table(:lastfm, primary_key: false) do
      add :user_id, :bigint, primary_key: true
      add :username, :string
    end
  end
end
