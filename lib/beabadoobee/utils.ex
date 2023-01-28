defmodule Beabadoobee.Utils do
  require Logger
  import Nostrum.Struct.Embed

  def maybe_log_error({:error, reason}), do: Logger.error(inspect(reason))
  def maybe_log_error(_), do: :ok
  def format_ping({:role, id}), do: "<@&#{id}>"
  def format_ping({:user, id}), do: "<@#{id}>"

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
end
