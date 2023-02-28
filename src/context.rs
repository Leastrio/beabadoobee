use std::sync::atomic::AtomicU16;

use dashmap::DashMap;
use sqlx::PgPool;
use twilight_http::Client;

pub struct BeaContext {
  pub http: Client,
  pub db: PgPool,
  pub meow_counters: DashMap<i64, AtomicU16>,
}
