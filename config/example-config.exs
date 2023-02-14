import Config

config :beabadoobee, Beabadoobee.Repo,
  database: "beabadoobee",
  username: "beabadoobee",
  password: "password",
  hostname: "database"

config :nostrum,
  token: "TOKEN",
  num_shards: :auto,
  gateway_intents: [
    :message_content,
    :guild_messages,
    :guild_members,
    :guild_message_reactions
  ],
  caches: %{
    guilds: Nostrum.Cache.GuildCache.NoOp
  }

config :logger,
  level: :info,
  metadata: [:shard, :guild, :channel]

config :tesla,
  adapter: Tesla.Adapter.Hackney

config :beabadoobee,
  ecto_repos: [Beabadoobee.Repo],
  general_chat: 0,
  welcome_role: 0,
  guild_id: 0,
  mee6_cookie: "",
  lastfm_key: "key"
