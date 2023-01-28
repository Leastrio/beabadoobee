defmodule Beabadoobee.Command do
  @type options :: [Nostrum.Struct.ApplicationCommand.command_option()]

  @callback description() :: String.t()
  @callback type() :: Nostrum.Struct.ApplicationCommand.command_type()
  @callback options() :: options
  @callback attributes() :: map()

  @optional_callbacks [
    {:attributes, 0},
    {:options, 0}
  ]
end
