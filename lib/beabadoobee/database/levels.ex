defmodule Beabadoobee.Database.Levels do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "levels" do
    field(:guild_id, :integer, primary_key: true)
    field(:user_id, :integer, primary_key: true)
    field(:xp, :integer)
  end

  def upsert_xp(guild_id, user_id, xp) do
    Beabadoobee.Repo.insert!(
      %__MODULE__{guild_id: guild_id, user_id: user_id, xp: xp},
      on_conflict: [inc: [xp: xp]],
      conflict_target: [:guild_id, :user_id]
    )
  end

  def get_member(guild_id, user_id) do
    query =
      from(m in Beabadoobee.Database.Levels,
        where: m.guild_id == ^guild_id and m.user_id == ^user_id
      )

    Beabadoobee.Repo.one(query)
  end

  def get_user_rank(guild_id, user_id) do
    query = """
    WITH userTbl AS (
      SELECT user_id, xp, rank() OVER(ORDER BY xp DESC) as rank
      FROM levels
      WHERE guild_id = $1
    )

    SELECT user_id, xp, rank
    FROM userTbl
    WHERE user_id = $2
    """

    Ecto.Adapters.SQL.query!(Beabadoobee.Repo, query, [guild_id, user_id])
      |> Map.get(:rows)
      |> List.first()
  end

  def get_top_and_user(guild_id, user_id) do
    query = """
    WITH userTbl AS (
      SELECT user_id, xp, rank() OVER(ORDER BY xp DESC) as rank
      FROM levels
      WHERE guild_id = $1
    )

    (SELECT user_id, xp, rank
      FROM userTbl
      ORDER BY xp DESC
      LIMIT 10)

    UNION

    SELECT user_id, xp, rank
    FROM userTbl
    WHERE user_id = $2
    ORDER BY xp DESC
    """

    Ecto.Adapters.SQL.query!(Beabadoobee.Repo, query, [guild_id, user_id])
      |> Map.get(:rows)
  end
end
