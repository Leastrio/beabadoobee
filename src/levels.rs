use std::sync::Arc;

use rand::Rng;
use twilight_model::{
  gateway::payload::incoming::MessageCreate,
  id::{marker::GuildMarker, Id},
};

use crate::{config, context::BeaContext, BeaResult};

pub async fn handle(
  ctx: Arc<BeaContext>,
  msg: &MessageCreate,
  guild_id: Id<GuildMarker>,
) -> BeaResult<()> {
  if let Some(level_channel_id) = ctx.state.guild_levels_enabled(guild_id) {
    if !ctx.state.in_cooldown(guild_id, msg.author.id) {
      let user = msg.author.id.get() as i64;
      let new_xp = gen_xp();
      let xp = sqlx::query!(
        "
        INSERT INTO levels
        VALUES($1, $2, $3)
        ON CONFLICT (guild_id, user_id)
        DO UPDATE SET xp = levels.xp + excluded.xp
        RETURNING xp
      ",
        guild_id.get() as i64,
        user,
        new_xp
      )
      .fetch_one(&ctx.db)
      .await?
      .xp;

      ctx.state.set_cooldown(guild_id, msg.author.id)?;
      let new_level = calc_level(xp);
      if new_level > calc_level(xp - new_xp) {
        match level_channel_id {
          0 => {
            ctx
              .http
              .create_message(msg.channel_id)
              .content(&format!(
                "<@{}> just leveled up to level {}",
                user, new_level
              ))?
              .await?;
          }
          _ => {
            ctx
              .http
              .create_message(Id::new(level_channel_id as u64))
              .content(&format!(
                "<@{}> just leveled up to level {}",
                user, new_level
              ))?
              .await?;
          }
        }
      }
      if let Some(role) = sqlx::query_as!(
        config::Reward,
        "SELECT * FROM role_rewards WHERE guild_id = $1",
        guild_id.get() as i64
      )
      .fetch_optional(&ctx.db)
      .await?
      {
        ctx
          .http
          .add_guild_member_role(guild_id, Id::new(user as u64), Id::new(role.role_id as u64))
          .await?;
      }
    }
  }
  Ok(())
}

fn gen_xp() -> i32 {
  let mut rng = rand::thread_rng();
  rng.gen_range(15..=25)
}

#[inline]
fn xp_for_level(level: i32) -> i32 {
  let level = level as f64;
  (5.0 / 6.0 * level * (2.0 * level * level + 27.0 * level + 91.0)) as i32
}

fn calc_level(xp: i32) -> i32 {
  let mut testxp = 0;
  let mut level = 0;
  while xp >= testxp {
    level += 1;
    testxp = xp_for_level(level);
  }
  level - 1
}
