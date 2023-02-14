defmodule Beabadoobee.Commands.Rank do
  @behaviour Beabadoobee.Command
  require Logger

  @impl true
  def description(), do: "View your chatting level in this server!"

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
    content = case options do
        [user] -> user.value
        _ -> interaction.user.id
    end
    |> gen_resp(interaction.guild_id)


    {:simple, content: content}
  end

  defp gen_resp(user_id, guild_id) do
    case Beabadoobee.Database.Levels.get_member(guild_id, user_id) do
      nil ->
        "User has not spoken yet.."

      entry ->
        level = Beabadoobee.Levels.calc_level(entry.xp)
        user = Nostrum.Api.get_user!(entry.user_id)
        "#{Nostrum.Struct.User.full_name(user)} is level #{level}"
    end
  end
end
