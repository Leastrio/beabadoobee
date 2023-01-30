defmodule Beabadoobee.Commands.Link do
  @behaviour Beabadoobee.Command
  require Logger

  @impl true
  def description(), do: "Link your lastfm"

  @impl true
  def type(), do: 1

  @impl true
  def options() do
    [
      %{
        name: "username",
        description: "lastfm username",
        type: 3,
        required: true
      }
    ]
  end

  @impl true
  def handle_application_command(interaction, options) do
    username = options
    |> List.first()
    |> Map.get(:value)

    with 200 <- Beabadoobee.Lastfm.user(username).status,
        {:ok, _} <- check_update(interaction.user.id, username) do
          {:simple, content: "Successfully linked your discord account to `#{username}`"}
        else
          _ ->
            {:simple, content: "An error happened, make sure you spelt your username correctly"}
        end
  end

  defp check_update(user_id, username) do
    case Beabadoobee.Repo.get(Beabadoobee.Database.Lastfm, user_id) do
      nil -> %Beabadoobee.Database.Lastfm{user_id: user_id}
      user -> user
    end
    |> Beabadoobee.Database.Lastfm.changeset(%{username: username})
    |> Beabadoobee.Repo.insert_or_update()
  end
end
