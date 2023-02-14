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

        last_level_req = Beabadoobee.Levels.xp_for_level(level)
        next_level_req = Beabadoobee.Levels.xp_for_level(level + 1)
        perc = Float.round(((entry.xp - last_level_req) / (next_level_req - last_level_req)), 2) * 100
        "#{user.username} is level #{level}\n#{perc}% on the way to level #{level + 1}!"
    end
  end
end
