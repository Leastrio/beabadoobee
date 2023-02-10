defmodule Beabadoobee.Database.Stars do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "stars" do
    field :msg_id, :integer, primary_key: true
    field :guild_id, :integer
    field :channel_id, :integer
    field :starboard_msg_id, :integer
  end

  def get_star_msg(id) do
    query = from e in Beabadoobee.Database.Stars,
      where: e.msg_id == ^id
    Beabadoobee.Repo.one(query)
  end

  def insert_star(msg_id, star_id) do
    Beabadoobee.Repo.insert!(%__MODULE__{
      msg_id: msg_id,
      starboard_msg_id: star_id
    })
  end
end
