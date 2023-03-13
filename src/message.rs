use std::sync::{atomic::Ordering, Arc, RwLock};

use lazy_static::{__Deref, lazy_static};
use rand::seq::SliceRandom;
use regex::{NoExpand, Regex};
use twilight_model::{
  gateway::payload::incoming::MessageCreate,
  id::{marker::GuildMarker, Id},
};

use crate::{
  config::{self, ChatMessage, ReqGptBody, RespGptBody},
  context::BeaContext,
  levels, utils, BeaResult,
};

lazy_static! {
  static ref MEOW_RE: Regex = Regex::new(r"(?i)m+ *e+ *o+ *w+").unwrap();
  static ref DEATHBED_RE: Regex = Regex::new(r"(?i)d+ *e+ *a+ *t+ *h+ *b+ *e+ *d+").unwrap();
  static ref MENTION_RE: Regex = Regex::new(&format!("<@{}>", config::BOT_ID)).unwrap();
}

const MEOWS: &[&str] = &[
  "meow",
  "MEOW",
  "MEEEEOOWWWWWW",
  "meow meow",
  r"/ᐠ｡ꞈ｡ᐟ\",
  r" /ᐠ｡ꞈ｡ᐟ✿\",
  r"—ฅ/ᐠ. ̫ .ᐟ\ฅ —",
];
const SONGS: &[&str] = &[
  "Beatopia Cultsong",
  "10:36",
  "Sunny Day",
  "See you Soon",
  "Ripples",
  "the perfect pair",
  "broken cd",
  "Talk",
  "Lovesong",
  "Pictures of Us",
  "fairy song",
  "Don't get the deal",
  "tinkerbell is overrated",
  "You're here that's the thing",
  "Glue Song",
];

pub async fn handle_create(ctx: Arc<BeaContext>, msg: MessageCreate) -> BeaResult<()> {
  if msg.author.bot {
    return Ok(());
  }

  if let Some(guild_id) = msg.guild_id {
    levels::handle(Arc::clone(&ctx), &msg, guild_id).await?;
    if msg.mentions.iter().any(|x| x.id == Id::new(config::BOT_ID)) {
      handle_bot_mention(
        Arc::clone(&ctx),
        &msg,
        MENTION_RE.replace_all(&msg.content, "").to_string(),
      )
      .await?;
    }
    handle_meow(Arc::clone(&ctx), &msg, guild_id).await?;
    maybe_meow(Arc::clone(&ctx), &msg, guild_id).await?;
    maybe_deathbed(Arc::clone(&ctx), &msg, guild_id).await?;
  }

  Ok(())
}

async fn maybe_deathbed(
  ctx: Arc<BeaContext>,
  msg: &MessageCreate,
  guild_id: Id<GuildMarker>,
) -> BeaResult<()> {
  if DEATHBED_RE.is_match(&msg.content) {
    match sqlx::query_as!(
      crate::config::Webhook,
      "
      SELECT webhook_id, webhook_token
      FROM guilds
      WHERE guild_id = $1
    ",
      guild_id.get() as i64
    )
    .fetch_one(&ctx.db)
    .await
    {
      Ok(data) => {
        if sentiment::analyze(msg.content.clone()).score >= 1.0 {
          ctx.http.delete_message(msg.channel_id, msg.id).await?;
          ctx
            .http
            .update_webhook(Id::new(data.webhook_id.unwrap() as u64))
            .channel_id(msg.channel_id)
            .await?;
          let song = {
            let mut rng = rand::thread_rng();
            SONGS.choose(&mut rng).unwrap_or(&"Ripples")
          };
          ctx
            .http
            .execute_webhook(
              Id::new(data.webhook_id.unwrap() as u64),
              &data.webhook_token.unwrap(),
            )
            .content(&DEATHBED_RE.replace_all(&msg.content, NoExpand(song)))?
            .username(
              &msg
                .member
                .clone()
                .unwrap()
                .nick
                .unwrap_or(msg.author.clone().name),
            )?
            .avatar_url(&utils::avatar_url(msg.0.clone())?)
            .await?;
        } else {
          ctx
            .http
            .create_message(msg.channel_id)
            .content("deathbed is trash")?
            .await?;
        }
      }
      Err(_) => {
        ctx
          .http
          .create_message(msg.channel_id)
          .content("deathbed is trash")?
          .await?;
      }
    };
  }
  Ok(())
}

async fn handle_meow(
  ctx: Arc<BeaContext>,
  msg: &MessageCreate,
  guild_id: Id<GuildMarker>,
) -> BeaResult<()> {
  if MEOW_RE.is_match(&msg.content) {
    sqlx::query!(
      "
          INSERT INTO meows
          VALUES($1, $2, 1)
          ON CONFLICT (guild_id, user_id)
          DO UPDATE SET meow_count = meows.meow_count + 1
        ",
      guild_id.get() as i64,
      msg.author.id.get() as i64
    )
    .execute(&ctx.db)
    .await?;
  }
  Ok(())
}

async fn maybe_meow(
  ctx: Arc<BeaContext>,
  msg: &MessageCreate,
  guild_id: Id<GuildMarker>,
) -> BeaResult<()> {
  match ctx.state.meow_counters.get(&guild_id) {
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

async fn handle_bot_mention(
  ctx: Arc<BeaContext>,
  msg: &MessageCreate,
  content: String,
) -> BeaResult<()> {
  let history = match ctx.state.chatgpt_cache.get(&msg.author.id) {
    Some(past_msgs) => {
      past_msgs.write().unwrap().push(ChatMessage::User(content));
      past_msgs.read().unwrap().deref().clone()
    }
    None => {
      let msgs = RwLock::new(vec![
        ChatMessage::System(config::PERSONALITY.to_string()),
        ChatMessage::User(content),
      ]);
      let msg_history = msgs.read().unwrap().deref().clone();
      ctx.state.chatgpt_cache.insert(msg.author.id, msgs);
      msg_history
    }
  };

  ctx.http.create_typing_trigger(msg.channel_id).await?;
  let res = ctx
    .req
    .post("https://api.openai.com/v1/chat/completions")
    .bearer_auth(std::env::var("OPENAI_KEY").expect("Could not find DISCORD_TOKEN"))
    .json(&ReqGptBody {
      model: String::from("gpt-3.5-turbo"),
      messages: history,
      temperature: 0.7,
      max_tokens: 256,
    })
    .send()
    .await?
    .json::<RespGptBody>()
    .await?;

  ctx
    .http
    .create_message(msg.channel_id)
    .content(&res.choices[0].message.to_string())?
    .reply(msg.id)
    .await?;

  if let Some(past_msgs) = ctx.state.chatgpt_cache.get(&msg.author.id) {
    past_msgs
      .write()
      .unwrap()
      .push(res.choices[0].message.clone())
  }

  Ok(())
}
