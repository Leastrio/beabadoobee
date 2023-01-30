defmodule Beabadoobee.Lastfm do
  use Tesla

  @api_key Application.compile_env!(:beabadoobee, :lastfm_key)

  plug Tesla.Middleware.BaseUrl, "https://ws.audioscrobbler.com/2.0/"
  plug Tesla.Middleware.Query, [api_key: @api_key, format: "json"]
  plug Tesla.Middleware.JSON

  def user(username) do
    get!("", query: [method: "user.getinfo", user: username])
  end
end
