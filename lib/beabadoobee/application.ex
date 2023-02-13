defmodule Beabadoobee.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      for i <- 1..System.schedulers_online(),
          do: Supervisor.child_spec({Beabadoobee.Consumer, []}, id: i)

    children =
      children ++
        [
          Beabadoobee.Repo,
          Beabadoobee.State.Supervisor
        ]

    opts = [strategy: :one_for_one, name: Beabadoobee.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
