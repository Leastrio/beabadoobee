defmodule Beabadoobee.Fun do
  require Logger
  alias Beabadoobee.State.Meow

  @meows ["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow"]
  @songs ["Beatopia Cultsong", "The Perfect Pair", "10:36", "Lovesong", "Ripples", "Sunny Day", "See you Soon"]
  @webhook_id Application.compile_env!(:beabadoobee, :webhook_id)
  @webhook_token Application.compile_env!(:beabadoobee, :webhook_token)

  def maybe_deathbed(%Nostrum.Struct.Message{} = msg) do
    if String.contains?(String.downcase(msg.content), ["deathbed", "death bed"]) do
      if msg.guild_id == 1072200154981089290 and Veritaserum.analyze(msg.content) >= 0 do
        Nostrum.Api.delete_message(msg)
        Nostrum.Api.execute_webhook(@webhook_id, @webhook_token, %{
          content: String.replace(msg.content, ~r/d+ *e+ *a+ *t+ *h+ *b+ *e+ *d+/i, Enum.random(@songs)),
          username: msg.author.username,
          avatar_url: Nostrum.Struct.User.avatar_url(msg.author)
        })
      else
        Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
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
