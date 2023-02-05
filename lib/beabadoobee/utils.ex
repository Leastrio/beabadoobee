defmodule Beabadoobee.Utils do
  require Logger
  import Nostrum.Struct.Embed

  def maybe_log_error({:error, reason}), do: Logger.error(inspect(reason))
  def maybe_log_error(_), do: :ok
  def format_ping({:role, id}), do: "<@&#{id}>"
  def format_ping({:user, id}), do: "<@#{id}>"
  def format_ping({:channel, id}), do: "<##{id}>"

  def delimit_num(num) do
    num
    |> to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map( & Enum.reverse(&1))
    |> Enum.reverse()
    |> Enum.join(",")
  end

  def welcome_embed() do
    %Nostrum.Struct.Embed{}
      |> put_title("˚୨୧⋆｡˚ ⋆welcome to the beacord! ⋆ ˚｡⋆୨୧˚")
      |> put_description("𝗵𝗶! 𝘄𝗲𝗹𝗰𝗼𝗺𝗲 𝘁𝗼 𝘁𝗵𝗲 𝗯𝗲𝗮𝗯𝗮𝗱𝗼𝗼𝗯𝗲𝗲 𝗱𝗶𝘀𝗰𝗼𝗿𝗱!

          <a:beagroovymove:927560576052383815> make sure to check out <#925652608620834878>, <#925652969855262750>, <#925653153565777960> <3

          We have an ongoing event happening! Check it out in <#925653068958277683>

          ***what's your favorite bea song?***")
      |> put_color(6960383)
      |> put_thumbnail("https://media.giphy.com/media/KkVPbGYUAZYdvcdv0A/giphy.gif")
  end

  def reply(interaction, data) do
    case interaction.type do
      2 -> Nostrum.Api.create_interaction_response!(interaction, %{type: 4, data: Map.new(data)})
    end
  end
end
