defmodule Beabadoobee.Commands.Leaderboard do
  @behaviour Beabadoobee.Command
  require Logger
  import Nostrum.Struct.Embed
  import Ecto.Query

  @impl true
  def description(), do: "View top speakers in the server"

  @impl true
  def type(), do: 1

  @impl true
  def handle_application_command(interaction, _options) do
    {:simple, embeds: [generate_embed(interaction.guild_id, interaction.user.id)]}
  end

  def get_top(guild_id) do
    query =
      from(u in Beabadoobee.Database.Levels,
        where: u.guild_id == ^guild_id,
        limit: 10,
        order_by: [desc: :xp]
      )
    Beabadoobee.Repo.all(query)
  end

  defp generate_embed(guild_id, invoker_id) do
    %Nostrum.Struct.Embed{}
    |> put_title("Leaderboard")
    |> put_color(6669007)
    |> put_description(gen_desc("", 1, get_top(guild_id), invoker_id))
  end

  def gen_desc(_desc, _count, [], _invoker_id), do: "No data found.."
  def gen_desc(desc, count, [head | tail], invoker_id) do
    case tail do
      [] -> desc <> "\n" <> gen_rank(count, head, invoker_id)
      _ -> gen_desc(desc <> "\n" <> gen_rank(count, head, invoker_id), count + 1, tail, invoker_id)
    end
  end

  def gen_rank(count, user, invoker_id) do
    cond do
      user.user_id == invoker_id ->
        "**#{count}: #{Beabadoobee.Utils.format_ping({:user, user.user_id})} Level: #{Beabadoobee.Levels.calc_level(user.xp)}**"
      true -> "#{count}: #{Beabadoobee.Utils.format_ping({:user, user.user_id})} Level: #{Beabadoobee.Levels.calc_level(user.xp)}"
    end
  end
end
