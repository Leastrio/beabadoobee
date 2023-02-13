defmodule Beabadoobee.Invoker do
  require Logger

  use Beabadoobee.ApplicationCommandInvoker,
    commands: %{
      "link" => Beabadoobee.Commands.Link,
      "profile" => Beabadoobee.Commands.Profile,
      "meow" => Beabadoobee.Commands.Meow,
      "meowtop" => Beabadoobee.Commands.MeowTop
    }

  def handle_interaction(interaction) do
    try do
      case interaction.type do
        2 -> handle_application_command(interaction)
      end
    rescue
      e ->
        try do
          Logger.error(inspect(e))
          Beabadoobee.Utils.reply(interaction, content: "An error occurred")
        rescue
          _ -> :ok
        end
    end
  end

  defp handle_application_command(interaction) do
    case fetch_command(interaction) do
      {:ok, {module, options}} -> invoke_application_command(interaction, module, options)
      :error -> Logger.warn("Command not found")
    end
  end

  defp invoke_application_command(interaction, module, options) do
    case module.handle_application_command(interaction, options) do
      {:simple, payload} -> Beabadoobee.Utils.reply(interaction, payload)
    end
  end

  def register_commands() do
    __commands__()
    |> build_payloads()
    |> Enum.each(fn payload ->
      case Nostrum.Api.create_global_application_command(payload) do
        {:error, error} -> Logger.error(error)
        _ -> :ok
      end
    end)

    Logger.info("Commands registered")
  end

  defp build_payloads(commands) do
    Enum.map(commands, fn {name, command} ->
      command
      |> command_attributes()
      |> Enum.into(%{
        type: command.type(),
        name: name,
        description: command.description(),
        options: command_options(command)
      })
    end)
  end

  defp command_options(command) do
    if function_exported?(command, :options, 0) do
      Enum.map(command.options(), fn option ->
        Map.update!(option, :type, &translate_option_type/1)
      end)
    else
      %{}
    end
  end

  defp command_attributes(command) do
    if function_exported?(command, :attributes, 0), do: command.attributes(), else: %{}
  end

  defp translate_option_type(:string), do: 3
  defp translate_option_type(integer) when is_integer(integer), do: integer
end
