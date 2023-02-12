defmodule Beabadoobee.Database.Meows do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "meows" do
    field :guild_id, :integer, primary_key: true
    field :user_id, :integer, primary_key: true
    field :meow_count, :integer
  end

  def upsert_meow(guild_id, user_id) do
    Beabadoobee.Repo.insert!(
      %__MODULE__{guild_id: guild_id, user_id: user_id, meow_count: 1},
      on_conflict: [inc: [meow_count: 1]],
      conflict_target: [:guild_id, :user_id]
      )
  end

  def get_member(guild_id, user_id) do
    query = from m in Beabadoobee.Database.Meows,
      where: m.guild_id == ^guild_id and m.user_id == ^user_id
    Beabadoobee.Repo.one(query)
  end
end
