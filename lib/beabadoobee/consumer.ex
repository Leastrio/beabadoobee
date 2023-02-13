defmodule Beabadoobee.Consumer do
  use Nostrum.Consumer
  require Logger
  alias Beabadoobee.Fun
  alias Beabadoobee.Utils

  @general_chat Application.compile_env!(:beabadoobee, :general_chat)
  @welcome_role Application.compile_env!(:beabadoobee, :welcome_role)
  @guild_id Application.compile_env!(:beabadoobee, :guild_id)

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, ready, _ws_state}) do
    Beabadoobee.Invoker.register_commands()
    Nostrum.Api.update_status(:online, "Ripples", 2)
    Logger.info("#{ready.user.username} is now ready!")
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state})
      when msg.author.bot do
    if msg.author.id == 159_985_870_458_322_944 do
      Beabadoobee.Levels.LevelRoles.handle_message(msg)
    end
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state}) do
    Beabadoobee.Levels.handle(msg)

    if Regex.match?(~r/m+ *e+ *o+ *w+/i, msg.content) do
      Fun.handle_meow(msg)
    end

    Fun.maybe_meow(msg)
    Fun.maybe_deathbed(msg)
  end

  def handle_event(
        {:GUILD_MEMBER_ADD, {guild_id, %Nostrum.Struct.Guild.Member{} = member}, _ws_state}
      ) do
    if guild_id == @guild_id do
      Nostrum.Api.create_message(@general_chat,
        content:
          Utils.format_ping({:role, @welcome_role}) <>
            " " <> Utils.format_ping({:user, member.user.id}),
        embeds: [Utils.welcome_embed()]
      )
      |> Utils.maybe_log_error()
    end
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Beabadoobee.Invoker.handle_interaction(interaction)
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD, %Nostrum.Struct.Event.MessageReactionAdd{} = reaction, _ws_state}
      ) do
    Beabadoobee.Star.handle_reaction_event({:add, reaction})
  end

  def handle_event(
        {:MESSAGE_REACTION_REMOVE, %Nostrum.Struct.Event.MessageReactionRemove{} = reaction,
         _ws_state}
      ) do
    Beabadoobee.Star.handle_reaction_event({:remove, reaction})
  end

  def handle_event(_event) do
    :noop
  end
end
