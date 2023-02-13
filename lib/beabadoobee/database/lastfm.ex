defmodule Beabadoobee.Database.Lastfm do
  use Ecto.Schema

  @primary_key false
  schema "lastfm" do
    field(:user_id, :integer, primary_key: true)
    field(:username, :string)
  end

  def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:user_id, :username])
    |> Ecto.Changeset.validate_required([:user_id, :username])
  end
end
