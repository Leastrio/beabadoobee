defmodule Beabadoobee.Database.Members do
  use Ecto.Schema

  @primary_key false
  schema "members" do
    field :guild_id, :integer, primary_key: true
    field :user_id, :integer, primary_key: true
    field :xp, :integer
    field :meow_count, :integer
  end

  def upsert_meow(guild_id, user_id) do
    Beabadoobee.Repo.insert!(
      %__MODULE__{guild_id: guild_id, user_id: user_id, meow_count: 1},
      on_conflict: [inc: [meow_count: 1]],
      conflict_target: [:guild_id, :user_id]
      )
  end
end
