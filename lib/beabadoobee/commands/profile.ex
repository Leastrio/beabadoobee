defmodule Beabadoobee.Commands.Profile do
  @behaviour Beabadoobee.Command
  require Logger
  import Nostrum.Struct.Embed

  @impl true
  def description(), do: "View your or a specified user's lastfm profile"

  @impl true
  def type(), do: 1

  @impl true
  def options() do
    [
      %{
        name: "user",
        description: "user to query",
        type: 6,
        required: false
      }
    ]
  end

  @impl true
  def handle_application_command(interaction, options) do
    user = case options do
      [user] -> user.value
      _ -> interaction.user.id
    end
    |> get_user()

    case user do
      :error -> {:simple, content: "User does not have lastfm linked."}
      user -> {:simple, embeds: [generate_embed(user.body["user"])]}
    end
  end

  defp get_user(id) do
    case Beabadoobee.Repo.get(Beabadoobee.Database.Lastfm, id) do
      nil -> :error
      user ->
        Beabadoobee.Lastfm.user(user.username)
    end
  end

  defp generate_embed(user) do
    %Nostrum.Struct.Embed{}
    |> put_title("#{user["name"]}'s profile")
    |> put_url(user["url"])
    |> put_thumbnail(Enum.find(user["image"], fn image -> image["size"] == "large" end)["#text"])
    |> put_field("Info", "Username: **#{user["name"]}**\nRegistered: <t:#{user["registered"]["unixtime"]}:D> (<t:#{user["registered"]["unixtime"]}:R>)")
    |> put_field("Play Counts", "")
  end
end
