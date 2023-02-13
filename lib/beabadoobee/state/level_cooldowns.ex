defmodule Beabadoobee.State.LevelCooldowns do
  use GenServer
  require Logger
  import Ecto.Query

  @table_name :levels
  @table_opts [
    :set,
    :named_table,
    :public,
    read_concurrency: true,
    write_concurrency: true
  ]

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    :ets.new(@table_name, @table_opts)

    query =
      from(g in Beabadoobee.Database.Guilds,
        where: not is_nil(g.level_up_channel_id)
      )

    Beabadoobee.Repo.all(query)
    |> fill_ets()

    {:ok, state}
  end

  def handle_cast({:enqueue, {guild_id, user_id}}, state) do
    new_state = Map.update(state, guild_id, [user_id], fn curr -> curr ++ [user_id] end)
    Process.send_after(self(), {:dequeue, {guild_id, user_id}}, :timer.minutes(1))
    {:noreply, new_state}
  end

  def handle_info({:dequeue, {guild_id, user_id}}, state) do
    {_curr, new_state} =
      Map.get_and_update(state, guild_id, fn curr ->
        {curr, curr -- [user_id]}
      end)

    {:noreply, new_state}
  end

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  def guild_enabled(guild_id) do
    case :ets.lookup(@table_name, guild_id) do
      [{_guild_id, channel_id}] -> channel_id
      [] -> nil
    end
  end

  def in_cooldown(guild_id, user_id) do
    case Map.get(GenServer.call(__MODULE__, :queue), guild_id) do
      nil -> false
      users -> Enum.member?(users, user_id)
    end
  end

  def enqueue(guild_id, user_id), do: GenServer.cast(__MODULE__, {:enqueue, {guild_id, user_id}})

  def fill_ets(nil), do: :ok
  def fill_ets([]), do: :ok

  def fill_ets([head | tail]) do
    case tail do
      [] ->
        :ets.insert(@table_name, {head.guild_id, head.level_up_channel_id})

      _ ->
        :ets.insert(@table_name, {head.guild_id, head.level_up_channel_id})
        fill_ets(tail)
    end
  end
end
