use std::sync::{atomic::Ordering, Arc};

use lazy_static::lazy_static;
use rand::seq::SliceRandom;
use regex::{Regex, NoExpand};
use twilight_model::{gateway::payload::incoming::MessageCreate, id::Id};

use crate::{context::BeaContext, BeaResult, utils, levels};

lazy_static! {
  static ref MEOW_RE: Regex = Regex::new(r"(?i)m+ *e+ *o+ *w+").unwrap();
  static ref DEATHBED_RE: Regex = Regex::new(r"(?i)d+ *e+ *a+ *t+ *h+ *b+ *e+ *d+").unwrap();
}

const MEOWS: &'static [&str] = &["meow", "MEOW", "MEEEEOOWWWWWW", "meow meow"];
const SONGS: &'static [&str] = &["Beatopia Cultsong", "10:36", "Sunny Day", "See you Soon", "Ripples", "the perfect pair", "broken cd", "Talk", "Lovesong", "Pictures of Us", "fairy song", "Don't get the deal", "tinkerbell is overrated", "You're here that's the thing", "Glue Song"];

pub async fn handle_create(ctx: Arc<BeaContext>, msg: MessageCreate) -> BeaResult<()> {
  if !msg.author.bot && msg.guild_id.is_some() {
    levels::handle(Arc::clone(&ctx), &msg).await?;

    let guild_id = msg.0.guild_id.unwrap().get() as i64;
    handle_meow(&msg, guild_id, Arc::clone(&ctx)).await?;
    maybe_meow(Arc::clone(&ctx), guild_id, &msg).await?;
    maybe_deathbed(Arc::clone(&ctx), &msg, guild_id).await?;
  }

  Ok(())
}

async fn maybe_deathbed(ctx: Arc<BeaContext>, msg: &MessageCreate, guild_id: i64) -> BeaResult<()> {
  if DEATHBED_RE.is_match(&msg.content) {
    match sqlx::query_as!(crate::config::Webhook, "
      SELECT webhook_id, webhook_token
      FROM guilds
      WHERE guild_id = $1
    ", guild_id).fetch_one(&ctx.db).await {
        Ok(data) => {
          if sentiment::analyze(msg.content.clone()).score >= 1.0 {
            ctx.http.delete_message(msg.channel_id, msg.id).await?;
            ctx.http.update_webhook(Id::new(data.webhook_id.unwrap() as u64)).channel_id(msg.channel_id).await?;
            let song = {
              let mut rng = rand::thread_rng();
              SONGS.choose(&mut rng).unwrap_or(&"Ripples")
            };
            ctx.http.execute_webhook(Id::new(data.webhook_id.unwrap() as u64), &data.webhook_token.unwrap())
              .content(&DEATHBED_RE.replace_all(&msg.content, NoExpand(song)))?
              .username(&msg.member.clone().unwrap().nick.unwrap_or(msg.author.clone().name))?
              .avatar_url(&utils::avatar_url(msg.clone())?)
              .await?;
          } else {
            ctx.http.create_message(msg.channel_id).content("deathbed is trash")?.await?;
          }
        },
        Err(_) => {
          ctx.http.create_message(msg.channel_id).content("deathbed is trash")?.await?;
        },
    };

  }
  Ok(())
}

async fn handle_meow(msg: &MessageCreate, guild_id: i64, ctx: Arc<BeaContext>) -> BeaResult<()> {
  if MEOW_RE.is_match(&msg.content) {
    sqlx::query!(
      "
          INSERT INTO meows
          VALUES($1, $2, 1)
          ON CONFLICT (guild_id, user_id)
          DO UPDATE SET meow_count = meows.meow_count + 1
        ",
      guild_id,
      msg.0.author.id.get() as i64
    )
    .execute(&ctx.db)
    .await?;
  }
  Ok(())
}

async fn maybe_meow(ctx: Arc<BeaContext>, guild_id: i64, msg: &MessageCreate) -> BeaResult<()> {
  match ctx.meow_counters.get(&guild_id) {
    Some(counter) => {
      if counter.load(Ordering::Relaxed) - 1 == 0 {
        let meow = {
          let mut rng = rand::thread_rng();
          MEOWS.choose(&mut rng).unwrap_or(&"meow")
        };
        ctx
          .http
          .create_message(msg.channel_id)
          .content(meow)?
          .await?;
      } else {
        counter.fetch_sub(1, Ordering::Relaxed);
      }
    }
    None => {}
  }
  Ok(())
}