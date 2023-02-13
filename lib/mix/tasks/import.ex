defmodule Mix.Tasks.Import do
  use Mix.Task
  use Tesla

  @mee6_cookie Application.compile_env!(:beabadoobee, :mee6_cookie)
  @guild_id Application.compile_env!(:beabadoobee, :guild_id)

  plug Tesla.Middleware.BaseUrl, "https://mee6.xyz/api/plugins/levels/leaderboard/"
  plug Tesla.Middleware.Headers, [{"Authorization", @mee6_cookie}]
  plug Tesla.Middleware.JSON

  def run(_) do
    Mix.Task.run("app.start")

    get_entries()
    |> insert_user()
  end

  def get_entries() do
    case get("#{@guild_id}?page=0") do
      {:ok, %{body: body}} ->
        get_entries(1, body["players"])
      err -> IO.inspect(err)
    end
  end

  def get_entries(page, players) do
    IO.inspect(page)
    case get("#{@guild_id}?page=#{page}") do
      {:ok, %{body: %{"players" => []}}} -> players
      {:ok, %{body: %{"players" => new_players}}} ->
        players ++ get_entries(page + 1, new_players)
      err -> IO.inspect(err)
    end
  end

  def insert_user([]), do: IO.puts("Done")
  def insert_user([head | body]) do
    Beabadoobee.Database.Levels.upsert_xp(@guild_id, String.to_integer(head["id"]), head["xp"])
    insert_user(body)
  end
end
