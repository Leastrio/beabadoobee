defmodule Beabadoobee.Fun do
  require Logger
  alias Beabadoobee.State.Meow

  @meows ["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow"]
  @songs ["Beatopia Cultsong", "10:36", "Sunny Day", "See you Soon", "Ripples", "the perfect pair", "broken cd", "Talk", "Lovesong", "Pictures of Us", "fairy song", "Don't get the deal", "tinkerbell is overrated", "You're here that's the thing"]

  def maybe_deathbed(%Nostrum.Struct.Message{} = msg) do
    if msg.content =~ ~r/d+ *e+ *a+ *t+ *h+ *b+ *e+ *d+/i do
      case Beabadoobee.Database.Guilds.get_webhook(msg.guild_id) do
        nil -> Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
        [id, token] ->
          if Veritaserum.analyze(msg.content) >= 1 do
            Nostrum.Api.delete_message(msg)
            Nostrum.Api.modify_webhook(id, %{channel_id: msg.channel_id})
            Nostrum.Api.execute_webhook(id, token, %{
              content: String.replace(msg.content, ~r/d+ *e+ *a+ *t+ *h+ *b+ *e+ *d+/i, Enum.random(@songs)),
              username: msg.author.username,
              avatar_url: Nostrum.Struct.User.avatar_url(msg.author)
            })
          else
            Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
          end
      end
    end
  end

  def maybe_meow(%Nostrum.Struct.Message{} = msg) do
    case Meow.value(msg.guild_id) do
      nil ->
        :ok

      {chan, num} ->
        if msg.channel_id == chan do
          Meow.decrement(msg.guild_id)

          if num - 1 == 0 do
            Meow.reset_counter(msg.guild_id, chan)
            Nostrum.Api.create_message(msg.channel_id, content: Enum.random(@meows))
          end
        end
    end
  end

  def handle_meow(%Nostrum.Struct.Message{} = msg) do
    Beabadoobee.Database.Meows.upsert_meow(msg.guild_id, msg.author.id)
  end
end
