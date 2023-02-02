defmodule Beabadoobee.Database.RoleRewards do
  use Ecto.Schema

  @primary_key false
  schema "role_rewards" do
    field :guild_id, :integer, primary_key: true
    field :role_id, :integer
    field :requirement, :integer
  end
end
