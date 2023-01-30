defmodule Beabadoobee.ApplicationCommandInvoker do
  alias Nostrum.Struct.Interaction

  defmacro __using__(opts) do
    {commands, _} = Keyword.fetch!(opts, :commands) |> Code.eval_quoted([], __CALLER__)
    fetch_command_clauses = build_fetch_clauses(commands)

    quote do
      def __commands__(), do: unquote(Macro.escape(commands))
      unquote(fetch_command_clauses)
    end
  end

  defp build_fetch_clauses(commands) do
    error_clause =
      quote do
        def fetch_command(_), do: :error
      end

    Enum.flat_map(commands, &do_build_fetch_clauses(&1, [])) ++ [error_clause]
  end

  defp do_build_fetch_clauses({name, module}, path) when is_atom(module) do
    data_match = build_data_match([name | path], module)

    [
      quote do
        def fetch_command(%Interaction{data: unquote(data_match)}) do
          {:ok, {unquote(module), options}}
        end
      end
    ]
  end

  defp build_data_match([name], module) do
    quote do
      %{name: unquote(name), type: unquote(module.type()), options: options}
    end
  end

  defp build_data_match([a, b], _module) do
    quote do
      %{name: unquote(b), type: 1, options: [%{name: unquote(a), options: options}]}
    end
  end

  defp build_data_match([a, b, c], _module) do
    quote do
      %{
        name: unquote(c),
        type: 1,
        options: [%{name: unquote(b), options: [%{name: unquote(a), options: options}]}]
      }
    end
  end
end
