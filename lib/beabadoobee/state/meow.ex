defmodule Beabadoobee.State.Meow do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:meow_counters, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    {:ok, %{}}
  end

  def value(id) do
    case :ets.lookup(:meow_counters, id) do
      [{_id, val}] -> val
      [] -> nil
    end
  end

  def decrement(id) do
    :ets.update_counter(:meow_counters, id, {1, -1})
  end

  def reset_counter(id) do
    num = random_num()
    :ets.insert(:meow_counters, {id, num})
  end

  def random_num do
    trunc(:rand.uniform() * (300 - 250) + 250)
  end
end
