defmodule Beabadoobee.Star do
  import Nostrum.Struct.Embed
  import Bitwise
  require Logger

  @starboard_channel Application.compile_env!(:beabadoobee, :starboard)
  @pluto_id Application.compile_env!(:beabadoobee, :pluto)

  def handle_reaction_event({type, reaction}) do
    if reaction.guild_id == @pluto_id and reaction.channel_id != @starboard_channel and reaction.emoji.name == "💧" do
      try do
        message = Nostrum.Api.get_channel_message!(reaction.channel_id, reaction.message_id)
        star_count = case message.reactions do
          nil -> 0
          reactions -> Enum.find(reactions, fn r -> r.emoji.name == "💧" end).count
        end
        
        if star_count >= 3 do
          case type do
            :add -> Beabadoobee.Star.handle_star(message, star_count)
            :remove -> Beabadoobee.Star.handle_star_remove(message, star_count)
          end
        end
      rescue
        e ->
          Logger.error(inspect e)
      end
    end
  end

  def handle_star(msg, stars) do
    case Beabadoobee.Database.Stars.get_star_msg(msg.id) do
      nil -> send_new_star(msg, stars)
      star_msg -> edit_star(msg, star_msg.starboard_msg_id, stars)
    end
  end

  def handle_star_remove(msg, stars) do
    case Beabadoobee.Database.Stars.get_star_msg(msg.id) do
      nil -> :ok
      star_msg -> edit_star(msg, star_msg.starboard_msg_id, stars)
    end
  end

  def send_new_star(msg, stars) do
    star_msg = Nostrum.Api.create_message!(
      @starboard_channel,
      content: "#{star_emoji(stars)} **#{stars}** #{Beabadoobee.Utils.format_ping({:channel, msg.channel_id})}",
      embeds: [gen_embed(msg, stars)]
      )
    Beabadoobee.Database.Stars.insert_star(msg.id, star_msg.id)
  end

  def edit_star(msg, star_id, stars) do
    Nostrum.Api.edit_message!(@starboard_channel, star_id, content: "#{star_emoji(stars)} **#{stars}** #{Beabadoobee.Utils.format_ping({:channel, msg.channel_id})}", embeds: [gen_embed(msg, stars)])
  end

  def gen_embed(msg, stars) do
    %Nostrum.Struct.Embed{}
    |> put_author(msg.author.username, "", Nostrum.Struct.User.avatar_url(msg.author))
    |> put_description(msg.content)
    |> put_field("Original", jump_url(msg.channel_id, msg.id))
    |> put_color(gen_color(stars))
    |> put_timestamp(DateTime.to_iso8601(msg.timestamp))
    |> maybe_put_image(msg)
  end

  def maybe_put_image(embed, msg) do
    with [head, _tail] <- msg.attachments,
      true <- Regex.match?(~r/.*((\.jpg)|(\.png)|(\.webp))/i, head.url) do
        embed |> put_image(head.url)
    else
      _ -> embed
    end
  end

  def gen_color(stars) do
    p = cond do
      stars / 8 > 1.0 -> 1.0
      true -> stars / 8
    end

    red = trunc((62 * p) + (212 * (1 - p)))
    green = trunc((183 * p) + (239 * (1 - p)))
    blue = 255
    (red <<< 16) + (green <<< 8) + blue
  end

  def jump_url(channel_id, msg_id) do
    "[Jump!](https://discord.com/channels/1055344742956806194/#{channel_id}/#{msg_id})"
  end

  def star_emoji(stars) do
    cond do
      5 > stars -> "💧"
      10 > stars and stars >= 5 -> "💦"
      true -> "🌊"
    end
  end
end
