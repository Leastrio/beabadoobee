defmodule Beabadoobee.Consumer do
  use Nostrum.Consumer
  require Logger
  alias Beabadoobee.Fun
  alias Beabadoobee.Utils

  @general_chat Application.compile_env!(:beabadoobee, :general_chat)
  @welcome_role Application.compile_env!(:beabadoobee, :welcome_role)
  @guild_id Application.compile_env!(:beabadoobee, :guild_id)
  @starboard_channel Application.compile_env!(:beabadoobee, :starboard)

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, _ready, _ws_state}) do
    Beabadoobee.Invoker.register_commands()
    Nostrum.Api.update_status(:online, "Ripples", 2)
    Logger.info("Bot is ready")
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state}) when msg.author.bot do
    if msg.author.id == 159985870458322944 do
      Beabadoobee.Levels.LevelRoles.handle_message(msg)
    end
  end

  def handle_event({:MESSAGE_CREATE, %Nostrum.Struct.Message{} = msg, _ws_state}) do
    if Regex.match?(~r/m+ *e+ *o+ *w+ */i, msg.content) do
      Fun.handle_meow(msg)
    end
    Fun.maybe_meow(msg)
    Fun.maybe_deathbed(msg)
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, %Nostrum.Struct.Guild.Member{} = member}, _ws_state}) do
    if guild_id == @guild_id do
      Nostrum.Api.create_message(@general_chat, content: Utils.format_ping({:role, @welcome_role}) <> " " <> Utils.format_ping({:user, member.user.id}), embeds: [Utils.welcome_embed])
        |> Utils.maybe_log_error()
    end
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Beabadoobee.Invoker.handle_interaction(interaction)
  end

  def handle_event({:MESSAGE_REACTION_ADD, %Nostrum.Struct.Event.MessageReactionAdd{} = reaction, _ws_state}) do
    if reaction.guild_id == @guild_id and reaction.channel_id != @starboard_channel and reaction.emoji.name == "💧" do
      try do
        message = Nostrum.Api.get_channel_message!(reaction.channel_id, reaction.message_id)
        star_count = message.reactions
        |> Enum.find(fn r -> r.emoji.name == "💧" end)
        |> Map.get(:count)

        if star_count >= 3 do
          Beabadoobee.Star.handle_star(message, star_count)
        end
      rescue
        e ->
          Logger.error(inspect e)
      end
    end
  end

  def handle_event(_event) do
    :noop
  end
end
