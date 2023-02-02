import Config

config :beabadoobee, Beabadoobee.Repo,
  database: "beabadoobee",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :nostrum,
  token: "TOKEN",
  num_shards: :auto,
  gateway_intents: [
    :message_content,
    :guild_messages,
    :guild_members
  ],
  caches: %{
    guilds: Nostrum.Cache.GuildCache.NoOp,
  }

config :tesla,
  adapter: Tesla.Adapter.Hackney

config :beabadoobee,
  ecto_repos: [Beabadoobee.Repo],
  general_chat: 0,
  welcome_role: 0,
  guild_id: 0,
  lastfm_key: "key",
  roles: %{
    level_5: 0,
    level_10: 0,
    level_15: 0,
    level_20: 0,
    level_25: 0,
    level_30: 0,
    level_35: 0,
  }
