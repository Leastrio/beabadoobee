defmodule Beabadoobee.Commands.Meow do
  @behaviour Beabadoobee.Command
  require Logger

  @impl true
  def description(), do: "meow"

  @impl true
  def type(), do: 1

  @impl true
  def handle_application_command(_interaction, _options) do
    {:simple, content: "meow"}
  end
end
