defmodule Beabadoobee.Database.Guilds do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "guilds" do
    field(:guild_id, :integer, primary_key: true)
    field(:meow_channel_id, :integer)
    field(:starboard_channel_id, :integer)
    field(:min_stars, :integer)
    field(:level_up_channel_id, :integer)
    field(:webhook_id, :integer)
    field(:webhook_token, :string)
  end

  def get_guild(id) do
    query =
      from(g in Beabadoobee.Database.Guilds,
        where: g.guild_id == ^id
      )

    Beabadoobee.Repo.one(query)
  end

  def get_webhook(guild_id) do
    query =
      from(g in __MODULE__,
        where: g.guild_id == ^guild_id,
        select: [g.webhook_id, g.webhook_token]
      )
    case Beabadoobee.Repo.one(query) do
      [nil, nil] -> nil
      [id, token] -> [id, token]
    end
  end
end
