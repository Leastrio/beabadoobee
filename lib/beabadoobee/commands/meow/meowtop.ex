defmodule Beabadoobee.Commands.MeowTop do
  @behaviour Beabadoobee.Command
  require Logger
  import Nostrum.Struct.Embed
  import Ecto.Query

  @impl true
  def description(), do: "View top meowers in the server"

  @impl true
  def type(), do: 1

  @impl true
  def handle_application_command(interaction, _options) do
    {:simple, embeds: [generate_embed(interaction.guild_id)]}
  end

  defp get_top(guild_id) do
    query =
      from(u in Beabadoobee.Database.Meows,
        where: u.guild_id == ^guild_id,
        limit: 10,
        order_by: [desc: :meow_count]
      )

    Beabadoobee.Repo.all(query)
  end

  defp generate_embed(guild_id) do
    %Nostrum.Struct.Embed{}
    |> put_title("Meow Top")
    |> put_description(gen_desc("", 1, get_top(guild_id)))
  end

  def gen_desc(_desc, _count, []), do: "Noone has meowed yet..."

  def gen_desc(desc, count, [head | tail]) do
    case tail do
      [] -> desc <> "\n" <> gen_rank(count, head)
      _ -> gen_desc(desc <> "\n" <> gen_rank(count, head), count + 1, tail)
    end
  end

  def gen_rank(count, user) do
    "**#{count}:** #{Beabadoobee.Utils.format_ping({:user, user.user_id})} #{Beabadoobee.Utils.delimit_num(user.meow_count)} meow(s)"
  end
end
