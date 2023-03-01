pub const BEACORD_ID: i64 = 925652253824667669;
pub const BEACORD_GEN_ID: u64 = 925652253824667669;

#[derive(Debug)]
pub struct Guild {
  pub guild_id: i64,
  pub meow_channel_id: Option<i64>,
  pub starboard_channel_id: Option<i64>,
  pub level_up_channel_id: Option<i64>,
  pub min_stars: Option<i32>,
  pub webhook_id: Option<i64>,
  pub webhook_token: Option<String>,
}

#[derive(Debug)]
pub struct Webhook {
  pub webhook_id: Option<i64>,
  pub webhook_token: Option<String>,
}

#[derive(Debug)]
pub struct Reward {
  pub guild_id: i64,
  pub role_id: i64,
  pub requirement: i32
}
