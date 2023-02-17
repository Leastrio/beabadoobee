defmodule Beabadoobee.Commands.Leaderboard do
  @behaviour Beabadoobee.Command
  require Logger
  import Nostrum.Struct.Embed

  @impl true
  def description(), do: "View top speakers in the server"

  @impl true
  def type(), do: 1

  @impl true
  def handle_application_command(interaction, _options) do
    {:simple, embeds: [generate_embed(interaction.guild_id, interaction.user.id)]}
  end

  defp generate_embed(guild_id, invoker_id) do
    %Nostrum.Struct.Embed{}
    |> put_title("Leaderboard")
    |> put_color(6669007)
    |> put_description(gen_desc("", Beabadoobee.Database.Levels.get_top_and_user(guild_id, invoker_id), invoker_id))
  end

  def gen_desc(_desc, [], _invoker_id), do: "No data found.."
  def gen_desc(desc, [head | tail], invoker_id) do
    case tail do
      [] -> desc <> "\n" <> gen_rank(head, invoker_id)
      _ -> gen_desc(desc <> "\n" <> gen_rank(head, invoker_id), tail, invoker_id)
    end
  end

  def gen_rank([user_id, xp, rank], invoker_id) do
    cond do
      user_id == invoker_id ->
        "**#{rank}: #{Beabadoobee.Utils.format_ping({:user, user_id})} Level: #{Beabadoobee.Levels.calc_level(xp)}**"
      true -> "#{rank}: #{Beabadoobee.Utils.format_ping({:user, user_id})} Level: #{Beabadoobee.Levels.calc_level(xp)}"
    end
  end
end
