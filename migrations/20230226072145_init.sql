-- Add migration script here
CREATE TABLE guilds (
  guild_id BIGINT PRIMARY KEY,
  meow_channel_id BIGINT,
  starboard_channel_id BIGINT,
  level_up_channel_id BIGINT,
  min_stars INTEGER,
  webhook_id BIGINT,
  webhook_token TEXT
);

CREATE TABLE meows (
  guild_id BIGINT,
  user_id BIGINT,
  meow_count INTEGER NOT NULL,
  PRIMARY KEY (guild_id, user_id)
);

CREATE TABLE role_rewards (
  guild_id BIGINT,
  requirement INTEGER,
  role_id BIGINT NOT NULL,
  PRIMARY KEY (guild_id, requirement)
);

CREATE TABLE starboard (
  msg_id BIGINT PRIMARY KEY,
  guild_id BIGINT NOT NULL,
  channel_id BIGINT NOT NULL,
  starboard_msg_id BIGINT NOT NULL
);

CREATE TABLE levels (
  guild_id BIGINT,
  user_id BIGINT,
  xp INTEGER,
  PRIMARY KEY (guild_id, user_id)
);