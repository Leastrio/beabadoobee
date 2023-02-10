defmodule Beabadoobee.Star do
  import Nostrum.Struct.Embed
  import Bitwise
  require Logger

  def handle_reaction_event({type, reaction}) do
    guild = Beabadoobee.Database.Guilds.get_guild(reaction.guild_id)
    if reaction.emoji.name == "💧" and guild != nil and Map.get(guild, :starboard_channel_id) != nil and reaction.channel_id != guild.starboard_channel_id do
      try do
        message = Nostrum.Api.get_channel_message!(reaction.channel_id, reaction.message_id)
        star_count = case message.reactions do
          nil -> 0
          reactions -> Enum.find(reactions, fn r -> r.emoji.name == "💧" end).count
        end

        if star_count >= guild.min_stars do
          case type do
            :add -> Beabadoobee.Star.handle_star(message, star_count, guild)
            :remove -> Beabadoobee.Star.handle_star_remove(message, star_count, guild)
          end
        end
      rescue
        e ->
          Logger.error(inspect e)
      end
    end
  end

  def handle_star(msg, stars, guild) do
    case Beabadoobee.Database.Stars.get_star_msg(msg.id) do
      nil -> send_new_star(msg, stars, guild)
      star_msg -> edit_star(msg, star_msg.starboard_msg_id, stars, guild)
    end
  end

  def handle_star_remove(msg, stars, guild) do
    case Beabadoobee.Database.Stars.get_star_msg(msg.id) do
      nil -> :ok
      star_msg -> edit_star(msg, star_msg.starboard_msg_id, stars, guild)
    end
  end

  def send_new_star(msg, stars, guild) do
    star_msg = Nostrum.Api.create_message!(
      guild.starboard_channel_id,
      content: "#{star_emoji(stars)} **#{stars}** #{Beabadoobee.Utils.format_ping({:channel, msg.channel_id})}",
      embeds: [gen_embed(msg, stars)],
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 5,
              label: "Jump to message",
              url: jump_url(guild.guild_id, msg.channel_id, msg.id)
            }
          ]
        }
      ]
      )
    Beabadoobee.Database.Stars.insert_star(msg.id, star_msg.id, guild.guild_id, msg.channel_id)
  end

  def edit_star(msg, star_id, stars, guild) do
    Nostrum.Api.edit_message!(
      guild.starboard_channel_id,
      star_id,
      content: "#{star_emoji(stars)} **#{stars}** #{Beabadoobee.Utils.format_ping({:channel, msg.channel_id})}",
      embeds: [gen_embed(msg, stars)],
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 5,
              label: "Jump to message",
              url: jump_url(guild.guild_id, msg.channel_id, msg.id)
            }
          ]
        }
      ]
      )
  end

  def gen_embed(msg, stars) do
    %Nostrum.Struct.Embed{}
    |> put_author(msg.author.username, "", Nostrum.Struct.User.avatar_url(msg.author))
    |> put_description(msg.content)
    |> put_color(gen_color(stars))
    |> put_timestamp(DateTime.to_iso8601(msg.timestamp))
    |> maybe_put_image(msg)
  end

  def maybe_put_image(embed, msg) do
    with [head, _tail] <- msg.attachments,
      true <- Regex.match?(~r/.*((\.jpg)|(\.png)|(\.webp))/i, head.url) do
        embed |> put_image(head.proxy_url)
    else
      _ -> embed
    end
  end

  def gen_color(stars) do
    p = cond do
      stars / 13 > 1.0 -> 1.0
      true -> stars / 13
    end

    red = trunc((0 * p) + (230 * (1 - p)))
    green = trunc((162 * p) + (246 * (1 - p)))
    blue = 255
    (red <<< 16) + (green <<< 8) + blue
  end

  def jump_url(guild_id, channel_id, msg_id) do
    "[Jump!](https://discord.com/channels/#{guild_id}/#{channel_id}/#{msg_id})"
  end

  def star_emoji(stars) do
    cond do
      5 > stars -> "💧"
      10 > stars and stars >= 5 -> "💦"
      true -> "🌊"
    end
  end
end
