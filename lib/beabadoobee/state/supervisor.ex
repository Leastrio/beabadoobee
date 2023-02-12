defmodule Beabadoobee.State.Supervisor do
  use Supervisor
  alias Beabadoobee.State

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    children = [
      State.LevelCooldowns,
      State.Meow
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
