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

  def handle_event({:READY, _ready, _ws_state}) do
    Logger.info("Bot is ready")
    Nostrum.Api.update_status(:online, "Ripples", 2)
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state}) when msg.author.bot do
    if msg.author.id == 159985870458322944 do
      Beabadoobee.Levels.LevelRoles.handle_message(msg)
    end
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state}) do
    Fun.maybe_deathbed(msg)
    Fun.maybe_meow(msg)
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, %Nostrum.Struct.Guild.Member{} = member}, _ws_state}) do
    if guild_id == @guild_id do
      Nostrum.Api.create_message(@general_chat, content: Utils.format_ping({:role, @welcome_role}) <> " " <> Utils.format_ping({:user, member.user.id}), embeds: [Utils.welcome_embed])
        |> Utils.maybe_log_error()
    end
  end

  def handle_event(_event) do
    :noop
  end
end
