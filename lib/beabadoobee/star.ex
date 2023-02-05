defmodule Beabadoobee.Star do
  import Nostrum.Struct.Embed
  import Bitwise

  @starboard_channel Application.compile_env!(:beabadoobee, :starboard)
  @guild_id Application.compile_env!(:beabadoobee, :guild_id)

  def handle_star(msg, stars) do
    in_queue(msg, stars)
  end

  def in_queue(msg, stars) do
    case Beabadoobee.Database.Stars.get_star_msg(msg.id) do
      nil -> send_new_star(msg, stars)
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
    "[Jump!](https://discord.com/channels/#{@guild_id}/#{channel_id}/#{msg_id})"
  end

  def star_emoji(stars) do
    cond do
      5 > stars -> "💧"
      10 > stars and stars >= 5 -> "💦"
      true -> "🌊"
    end
  end
end
