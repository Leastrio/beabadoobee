defmodule Beabadoobee.Fun do
  require Logger
  alias Beabadoobee.State.Meow

  @meows ["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow"]

  def maybe_deathbed(%Nostrum.Struct.Message{} = msg) do
    if String.contains?(String.downcase(msg.content), ["deathbed", "death bed"]) do
      Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
    end
  end

  def maybe_meow(%Nostrum.Struct.Message{} = msg) do
    case Meow.value(msg.guild_id) do
      nil -> :ok
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
    Beabadoobee.Database.Members.upsert_meow(msg.guild_id, msg.author.id)
  end
end
