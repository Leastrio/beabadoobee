defmodule Beabadoobee.State.Meow do
  use GenServer
  require Logger
  import Ecto.Query

  @table_name :meow_counters
  @table_opts [
    :set,
    :named_table,
    :public,
    read_concurrency: true,
    write_concurrency: true
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table_name, @table_opts)

    query =
      from(g in Beabadoobee.Database.Guilds,
        where: not is_nil(g.meow_channel_id)
      )

    Beabadoobee.Repo.all(query)
    |> fill_ets()

    {:ok, %{}}
  end

  def value(id) do
    case :ets.lookup(@table_name, id) do
      [{_guild_id, chan_id, val}] -> {chan_id, val}
      [] -> nil
    end
  end

  def decrement(id) do
    :ets.update_counter(@table_name, id, {3, -1})
  end

  def reset_counter(guild_id, channel_id) do
    :ets.insert(@table_name, {guild_id, channel_id, random_num()})
  end

  def fill_ets(nil), do: :ok
  def fill_ets([]), do: :ok

  def fill_ets([head | tail]) do
    case tail do
      [] ->
        :ets.insert(@table_name, {head.guild_id, head.meow_channel_id, random_num()})

      _ ->
        :ets.insert(@table_name, {head.guild_id, head.meow_channel_id, random_num()})
        fill_ets(tail)
    end
  end

  def random_num do
    Enum.random(250..300)
  end
end
