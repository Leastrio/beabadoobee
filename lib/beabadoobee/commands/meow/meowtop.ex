defmodule Beabadoobee.Commands.MeowTop do
  @behaviour Beabadoobee.Command
  require Logger
  import Nostrum.Struct.Embed

  @impl true
  def description(), do: "View top meowers in the server"

  @impl true
  def type(), do: 1

  @impl true
  def handle_application_command(interaction, _options) do
    {:simple, embeds: [generate_embed(interaction.guild_id, interaction.user.id)]}
  end

  defp generate_embed(guild_id, invoker_id) do
    %Nostrum.Struct.Embed{}
    |> put_title("Meow Top")
    |> put_description(gen_desc("", Beabadoobee.Database.Meows.get_top_and_user(guild_id, invoker_id), invoker_id))
  end

  def gen_desc(_desc, [], _invoker_id), do: "Noone has meowed yet..."

  def gen_desc(desc, [head | tail], invoker_id) do
    case tail do
      [] -> desc <> "\n" <> gen_rank(head, invoker_id)
      _ -> gen_desc(desc <> "\n" <> gen_rank(head, invoker_id), tail, invoker_id)
    end
  end

  def gen_rank([user_id, meow_count, rank], invoker_id) do
    cond do
      user_id == invoker_id ->
        "**#{rank}: #{Beabadoobee.Utils.format_ping({:user, user_id})} #{meow_count} meows(s)**"
      true -> "#{rank}: #{Beabadoobee.Utils.format_ping({:user, user_id})} #{meow_count} meows(s)"
    end
  end
end
