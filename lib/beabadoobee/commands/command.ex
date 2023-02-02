defmodule Beabadoobee.Command do
  @type interaction :: Nostrum.Struct.Interaction.t()
  @type options :: [Nostrum.Struct.ApplicationCommand.command_option()]
  @type message_payload :: map() | keyword()

  @type simple_response :: {:simple, message_payload()}
  @type response :: simple_response()

  @callback description() :: String.t()
  @callback type() :: Nostrum.Struct.ApplicationCommand.command_type()
  @callback options() :: options
  @callback attributes() :: map()

  @callback handle_application_command(interaction, options) :: response()

  @optional_callbacks [
    {:attributes, 0},
    {:options, 0}
  ]
end
