defmodule Beabadoobee.Database.Guilds do
  use Ecto.Schema

  @primary_key false
  schema "guilds" do
    field :guild_id, :integer, primary_key: true
    field :meow_channel_id, :integer
  end
end
