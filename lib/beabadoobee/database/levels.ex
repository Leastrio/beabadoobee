defmodule Beabadoobee.Database.Levels do
  use Ecto.Schema

  @primary_key false
  schema "levels" do
    field :guild_id, :integer, primary_key: true
    field :user_id, :integer, primary_key: true
    field :xp, :integer
    field :meow_count, :integer
  end
end
