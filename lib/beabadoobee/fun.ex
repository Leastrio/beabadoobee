defmodule Beabadoobee.Fun do

  @meows ["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow", "moew"]

  def maybe_deathbed(%Nostrum.Struct.Message{} = msg) do
    if String.contains?(String.downcase(msg.content), ["deathbed", "death bed"]) do
      Nostrum.Api.create_message(msg.channel_id, content: "deathbed is trash")
    end
  end

  def maybe_meow(%Nostrum.Struct.Message{} = msg) do
    Beabadoobee.State.Meow.decrement()
    if Beabadoobee.State.Meow.value == 0 do
      Beabadoobee.State.Meow.reset_counter()
      Nostrum.Api.create_message(msg.channel_id, content: Enum.random(@meows))
    end
  end
end
