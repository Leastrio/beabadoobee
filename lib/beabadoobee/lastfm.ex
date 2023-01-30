defmodule Beabadoobee.Lastfm do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://ws.audioscrobbler.com/2.0/"
  plug Tesla.Middleware.Query, [api_key: "57fa8dffcd2f89b02cc42cfe5eeeeebe", format: "json"]
  plug Tesla.Middleware.JSON

  def user(username) do
    get!("", query: [method: "user.getinfo", user: username])
  end
end
