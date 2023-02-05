defmodule Beabadoobee.State.Meow do
  use GenServer
  require Logger
  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:meow_counters, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    query = from g in Beabadoobee.Database.Guilds,
      where: not is_nil(g.meow_channel_id)
    Beabadoobee.Repo.all(query)
    |> fill_ets()
    {:ok, %{}}
  end

  def value(id) do
    case :ets.lookup(:meow_counters, id) do
      [{_guild_id, chan_id, val}] -> {chan_id, val}
      [] -> nil
    end
  end

  def decrement(id) do
    :ets.update_counter(:meow_counters, id, {3, -1})
  end

  def reset_counter(guild_id, channel_id) do
    :ets.insert(:meow_counters, {guild_id, channel_id, random_num()})
  end

  def fill_ets(nil), do: :ok
  def fill_ets([]), do: :ok
  def fill_ets([head | tail]) do
    case tail do
      [] -> :ets.insert(:meow_counters, {head.guild_id, head.meow_channel_id, random_num()})
      _ ->
        :ets.insert(:meow_counters, {head.guild_id, head.meow_channel_id, random_num()})
        fill_ets(tail)
    end
  end

  def random_num do
    trunc(:rand.uniform() * (300 - 250) + 250)
  end
end
