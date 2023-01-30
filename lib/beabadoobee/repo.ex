defmodule Beabadoobee.Repo do
  use Ecto.Repo,
    otp_app: :beabadoobee,
    adapter: Ecto.Adapters.Postgres
end
