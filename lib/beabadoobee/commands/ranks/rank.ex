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
    case Beabadoobee.Database.Levels.get_user_rank(guild_id, user_id) do
      nil ->
        "User has not spoken yet.."

      [user_id, xp, rank] ->
        level = Beabadoobee.Levels.calc_level(xp)
        user = Nostrum.Api.get_user!(user_id)

        last_level_req = Beabadoobee.Levels.xp_for_level(level)
        next_level_req = Beabadoobee.Levels.xp_for_level(level + 1)
        perc = trunc(Float.round(((xp - last_level_req) / (next_level_req - last_level_req)), 2) * 100)
        "#{user.username} is level #{level}\n#{xp - last_level_req} / #{next_level_req - last_level_req}\n#{perc}% on the way to level #{level + 1}\n##{rank} in the server!"
    end
  end
end
