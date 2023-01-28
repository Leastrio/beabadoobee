defmodule Beabadoobee.State.Meow do
  use Agent
  require Logger

  def start_link(_args) do
    Agent.start_link(fn -> random_num() end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def decrement do
    Agent.update(__MODULE__ , &(&1 - 1))
  end

  def reset_counter do
    num = random_num()
    Agent.update(__MODULE__, fn _state -> num end)
    Logger.info("Waiting for " <> to_string(num) <> " messages")
  end

  def random_num do
    trunc(:rand.uniform() * (300 - 250) + 250)
  end
end
