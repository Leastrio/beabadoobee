use std::{collections::HashSet, sync::{atomic::AtomicU16, Arc}, time::Duration};

use dashmap::DashMap;
use rand::Rng;
use sqlx::PgPool;
use twilight_http::Client;
use twilight_model::id::{
  marker::{GuildMarker, UserMarker},
  Id,
};

use crate::{config, BeaResult};

pub struct BeaContext {
  pub http: Client,
  pub db: PgPool,
  pub state: BeaState,
}

pub struct BeaState {
  pub guild_configs: Arc<DashMap<Id<GuildMarker>, config::Guild>>,
  pub meow_counters: Arc<DashMap<Id<GuildMarker>, AtomicU16>>,
  pub level_cooldowns: Arc<DashMap<Id<GuildMarker>, HashSet<Id<UserMarker>>>>,
}

impl BeaState {
  pub async fn new(db: &PgPool) -> Self {
    Self {
      guild_configs: init_guild_configs(db)
        .await
        .expect("Could not populate guild config cache"),
      meow_counters: init_meow_counters(db)
        .await
        .expect("Could not init meow counters"),
      level_cooldowns: init_level_cooldowns(db)
        .await
        .expect("Could not populate level cooldown map"),
    }
  }

  pub fn guild_levels_enabled(&self, guild_id: Id<GuildMarker>) -> Option<i64> {
    match self.guild_configs.get(&guild_id) {
      Some(guild) => match guild.level_up_channel_id {
        Some(channel_id) => Some(channel_id),
        None => None,
      },
      None => None,
    }
  }

  pub fn in_cooldown(&self, guild_id: Id<GuildMarker>, user_id: Id<UserMarker>) -> bool {
    match self.level_cooldowns.get(&guild_id).unwrap().get(&user_id) {
      Some(_) => true,
      None => false,
    }
  }

  pub fn set_cooldown(&self, guild_id: Id<GuildMarker>, user_id: Id<UserMarker>) -> BeaResult<()> {
    self.level_cooldowns.get_mut(&guild_id).unwrap().insert(user_id);

    let cooldowns = Arc::downgrade(&self.level_cooldowns);
    tokio::spawn(async move {
      tokio::time::sleep(Duration::from_secs(60)).await;
      if let Some(cooldowns) = cooldowns.upgrade() {
        cooldowns.get_mut(&guild_id).unwrap().remove(&user_id);
      }
    });
    Ok(())
  }
}

async fn init_level_cooldowns(
  db: &PgPool,
) -> BeaResult<Arc<DashMap<Id<GuildMarker>, HashSet<Id<UserMarker>>>>> {
  let guilds = DashMap::new();
  for guild in sqlx::query_as!(
    config::Guild,
    "SELECT * FROM guilds WHERE level_up_channel_id IS NOT NULL"
  )
  .fetch_all(db)
  .await?
  {
    guilds.insert(Id::new(guild.guild_id as u64), HashSet::new());
  }
  Ok(Arc::new(guilds))
}

async fn init_guild_configs(db: &PgPool) -> BeaResult<Arc<DashMap<Id<GuildMarker>, config::Guild>>> {
  let guilds = DashMap::new();
  for guild in sqlx::query_as!(config::Guild, "SELECT * FROM guilds")
    .fetch_all(db)
    .await?
  {
    guilds.insert(Id::new(guild.guild_id as u64), guild);
  }
  Ok(Arc::new(guilds))
}

async fn init_meow_counters(db: &PgPool) -> BeaResult<Arc<DashMap<Id<GuildMarker>, AtomicU16>>> {
  let counters = DashMap::new();
  let mut rng = rand::thread_rng();
  for guild in sqlx::query_as!(
    config::Guild,
    "SELECT * FROM guilds WHERE meow_channel_id IS NOT NULL"
  )
  .fetch_all(db)
  .await?
  {
    counters.insert(
      Id::new(guild.guild_id as u64),
      AtomicU16::new(rng.gen_range(250..=300)),
    );
  }
  Ok(Arc::new(counters))
}
