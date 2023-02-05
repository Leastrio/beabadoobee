defmodule Beabadoobee.State.Star do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_cast({:enqueue, {msg_id, star_id}}, state) do
    Process.send_after(self(), {:dequeue, msg_id}, :timer.hours(1))
    {:noreply, state ++ [{msg_id, star_id}]}
  end

  def handle_info({:dequeue, msg_id}, state) do
    {:noreply, List.keydelete(state, msg_id, 0)}
  end

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(msg_id, star_id), do: GenServer.cast(__MODULE__, {:enqueue, {msg_id, star_id}})
end
