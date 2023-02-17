defmodule Beabadoobee.Database.Meows do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "meows" do
    field(:guild_id, :integer, primary_key: true)
    field(:user_id, :integer, primary_key: true)
    field(:meow_count, :integer)
  end

  def upsert_meow(guild_id, user_id) do
    Beabadoobee.Repo.insert!(
      %__MODULE__{guild_id: guild_id, user_id: user_id, meow_count: 1},
      on_conflict: [inc: [meow_count: 1]],
      conflict_target: [:guild_id, :user_id]
    )
  end

  def get_member(guild_id, user_id) do
    query =
      from(m in Beabadoobee.Database.Meows,
        where: m.guild_id == ^guild_id and m.user_id == ^user_id
      )

    Beabadoobee.Repo.one(query)
  end

  def get_top_and_user(guild_id, user_id) do
    query = """
    WITH userTbl AS (
      SELECT user_id, meow_count, rank() OVER(ORDER BY meow_count DESC) as rank
      FROM meows
      WHERE guild_id = $1
    )

    (SELECT user_id, meow_count, rank
      FROM userTbl
      ORDER BY meow_count DESC
      LIMIT 10)

    UNION

    SELECT user_id, meow_count, rank
    FROM userTbl
    WHERE user_id = $2
    ORDER BY meow_count DESC
    """

    Ecto.Adapters.SQL.query!(Beabadoobee.Repo, query, [guild_id, user_id])
      |> Map.get(:rows)
  end
end
