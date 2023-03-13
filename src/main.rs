mod commands;
mod config;
mod context;
mod database;
mod levels;
mod message;
mod starboard;
mod utils;

use std::{
  env,
  error::Error,
  sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
  },
};

use tokio::signal::unix::{signal, SignalKind};
use tracing::{error, info, warn};
use twilight_gateway::{CloseFrame, Config, Event, Intents, Shard, ShardId};
use twilight_http::Client;
use twilight_mention::Mention;
use twilight_model::{
  gateway::{
    payload::{incoming::MemberAdd, outgoing::update_presence::UpdatePresencePayload},
    presence::{ActivityType, MinimalActivity, Status},
  },
  id::Id,
};
use twilight_util::builder::embed::{EmbedBuilder, ImageSource};

use crate::context::{BeaContext, BeaState};

pub type BeaResult<T> = Result<T, Box<dyn Error + Send + Sync>>;

static SHUTDOWN: AtomicBool = AtomicBool::new(false);

#[tokio::main]
async fn main() {
  tracing_subscriber::fmt::init();

  let token = std::env::var("DISCORD_TOKEN")
    .expect("Could not find DISCORD_TOKEN")
    .trim()
    .to_string();
  let http = Client::new(token.clone());

  let current_app = http
    .current_user_application()
    .await
    .expect("Could not get current bot user")
    .model()
    .await
    .expect("Could not deserialize user body");
  let interaction = http.interaction(current_app.id);

  // interaction
  //     .set_global_commands(&commands::commands())
  //     .await?;

  let intents = Intents::MESSAGE_CONTENT
    | Intents::GUILD_MESSAGES
    | Intents::GUILD_MEMBERS
    | Intents::GUILD_MESSAGE_REACTIONS;

  let config = Config::builder(token.clone(), intents)
    .presence(
      UpdatePresencePayload::new(
        vec![MinimalActivity {
          kind: ActivityType::Listening,
          name: "Ripples".into(),
          url: None,
        }
        .into()],
        false,
        None,
        Status::Online,
      )
      .expect("Could not create presence payload"),
    )
    .build();

  let db = database::db_connect(&env::var("DATABASE_URL").expect("Could not find DATABASE_URL"))
    .await
    .expect("Could not connect to database");

  let state = BeaState::new(&db).await;
  let req = reqwest::Client::new();

  let context = Arc::new(BeaContext {
    http,
    db,
    state,
    req,
  });

  let mut shard = Shard::with_config(ShardId::ONE, config);
  info!("Shard Created.");
  let sender = shard.sender();

  let mut sigint = signal(SignalKind::interrupt()).expect("Could not register SIGINT handler");
  let mut sigterm = signal(SignalKind::terminate()).expect("Could not register SIGTERM handler");

  tokio::spawn(async move {
    tokio::select! {
        _ = sigint.recv() => tracing::debug!("received SIGINT"),
        _ = sigterm.recv() => tracing::debug!("received SIGTERM"),
    }

    tracing::debug!("shutting down");

    SHUTDOWN.store(true, Ordering::Relaxed);
    _ = sender.close(CloseFrame::NORMAL);
  });

  loop {
    match shard.next_event().await {
      Ok(event) => tokio::spawn(handle(event, Arc::clone(&context))),
      Err(source) => {
        warn!(?source, "Error receiving event");

        if source.is_fatal() {
          break;
        }

        continue;
      }
    };
    if SHUTDOWN.load(Ordering::Relaxed) {
      break;
    }
  }
}

async fn handle(event: Event, ctx: Arc<BeaContext>) {
  let res: BeaResult<()> = match event {
    Event::Ready(r) => {
      let ready = *r;
      info!("{} is ready", ready.user.name);
      Ok(())
    }
    Event::MessageCreate(msg) => message::handle_create(ctx, *msg).await,
    Event::MemberAdd(member_add) => {
      if member_add.guild_id == config::BEACORD_ID {
        send_beacord_welcome(*member_add, ctx).await
      } else if member_add.guild_id == config::PLUTOCORD_ID {
        send_plutocord_welcome(*member_add, ctx).await
      } else {
        Ok(())
      }
    }
    Event::ReactionAdd(reaction_add) => starboard::handle_react(ctx, *reaction_add).await,
    Event::ReactionRemove(reaction_remove) => starboard::handle_remove(ctx, *reaction_remove).await,
    _ => Ok(()),
  };
  match res {
    Ok(()) => {}
    Err(why) => error!(why, "Error in event"),
  }
}

async fn send_beacord_welcome(member_add: MemberAdd, ctx: Arc<BeaContext>) -> BeaResult<()> {
  let embed = EmbedBuilder::new()
    .title("˚୨୧⋆｡˚ ⋆welcome to the beacord! ⋆ ˚｡⋆୨୧˚")
    .description("𝗵𝗶! 𝘄𝗲𝗹𝗰𝗼𝗺𝗲 𝘁𝗼 𝘁𝗵𝗲 𝗯𝗲𝗮𝗯𝗮𝗱𝗼𝗼𝗯𝗲𝗲 𝗱𝗶𝘀𝗰𝗼𝗿𝗱!

    <a:beagroovymove:927560576052383815> make sure to check out <#925652608620834878>, <#925652969855262750>, <#925653153565777960> <3

    We have an ongoing event happening! Check it out in <#925653068958277683>

    ***what's your favorite bea song?***")
    .color(0x6A34FF)
    .thumbnail(ImageSource::url("https://media.giphy.com/media/KkVPbGYUAZYdvcdv0A/giphy.gif")?)
    .build();

  ctx
    .http
    .create_message(Id::new(config::BEACORD_GEN_ID))
    .content(&format!(
      "<@&926971203309162546> {}",
      member_add.user.id.mention()
    ))?
    .embeds(&[embed])?
    .await?;

  Ok(())
}

async fn send_plutocord_welcome(member_add: MemberAdd, ctx: Arc<BeaContext>) -> BeaResult<()> {
  let embed = EmbedBuilder::new()
    .title("welcome!")
    .description(format!(
      "haii {}, welcome to pluto cord!\nmake sure to get some <#1055345087833456770> :3",
      member_add.user.id.get()
    ))
    .color(0xff7573)
    .build();

  ctx
    .http
    .create_message(Id::new(config::BEACORD_GEN_ID))
    .embeds(&[embed])?
    .await?;

  Ok(())
}
