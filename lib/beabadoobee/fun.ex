defmodule Beabadoobee.Fun do
  alias Beabadoobee.State.Meow

  @meows ["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow", "moew"]

  def maybe_deathbed(%Nostrum.Struct.Message{} = msg) do
    if String.contains?(String.downcase(msg.content), ["deathbed", "death bed"]) do
      Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
    end
  end

  def handle_meow(%Nostrum.Struct.Message{} = msg) do
    case Meow.value(msg.guild_id) do
      nil -> Meow.reset_counter(msg.guild_id)
      num ->
        Meow.decrement(msg.guild_id)
        if num - 1 == 0 do
          Meow.reset_counter(msg.guild_id)
          Nostrum.Api.create_message(msg.channel_id, content: Enum.random(@meows))
        end
    end
  end
end
