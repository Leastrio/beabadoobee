defmodule Beabadoobee.Database.Lastfm do
  use Ecto.Schema

  @primary_key false
  schema "guilds" do
    field :guild_id, :integer, primary_key: true
    field :username, :string
  end
end
