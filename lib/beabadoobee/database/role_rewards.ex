defmodule Beabadoobee.Database.RoleRewards do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "role_rewards" do
    field(:guild_id, :integer, primary_key: true)
    field(:role_id, :integer)
    field(:requirement, :integer)
  end

  def get_reward(guild_id, level) do
    query =
      from(r in Beabadoobee.Database.RoleRewards,
        where: r.guild_id == ^guild_id and r.requirement == ^level
      )

    Beabadoobee.Repo.one(query)
  end
end
