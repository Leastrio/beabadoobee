use std::sync::Arc;

use twilight_mention::Mention;
use twilight_model::{
  channel::{
    message::{
      component::{ActionRow, Button, ButtonStyle},
      Component, Embed, ReactionType,
    },
    Message,
  },
  gateway::payload::incoming::{ReactionAdd, ReactionRemove},
  id::Id,
};
use twilight_util::builder::embed::{EmbedAuthorBuilder, EmbedBuilder, ImageSource};

use crate::{
  config::{Guild, StarMsg},
  context::BeaContext,
  utils, BeaResult,
};

pub async fn handle_react(ctx: Arc<BeaContext>, reaction_add: ReactionAdd) -> BeaResult<()> {
  if reaction_add.emoji
    == (ReactionType::Unicode {
      name: "💧".to_owned(),
    })
  {
    return Ok(());
  }
  let guild_config = sqlx::query_as!(
    Guild,
    "SELECT * FROM guilds WHERE guild_id = $1",
    reaction_add.guild_id.unwrap().get() as i64
  )
  .fetch_one(&ctx.db)
  .await?;
  if let Some(starboard_id) = guild_config.starboard_channel_id {
    if reaction_add.channel_id == starboard_id {
      return Ok(());
    }

    let msg = ctx
      .http
      .message(reaction_add.channel_id, reaction_add.message_id)
      .await?
      .model()
      .await?;
    let star_count = msg
      .reactions
      .iter()
      .filter(|r| {
        r.emoji
          == ReactionType::Unicode {
            name: "💧".to_owned(),
          }
      })
      .count();
    if star_count < guild_config.min_stars.unwrap() as usize {
      return Ok(());
    }

    if let Some(star_msg) = sqlx::query_as!(
      StarMsg,
      "SELECT * FROM starboard WHERE msg_id = $1",
      reaction_add.message_id.get() as i64
    )
    .fetch_optional(&ctx.db)
    .await?
    {
      edit_star(ctx, msg, star_count, guild_config, star_msg).await?;
    } else {
      create_star(ctx, msg, star_count, guild_config).await?;
    }
  }
  Ok(())
}

pub async fn handle_remove(ctx: Arc<BeaContext>, reaction_remove: ReactionRemove) -> BeaResult<()> {
  if reaction_remove.emoji
    == (ReactionType::Unicode {
      name: "💧".to_owned(),
    })
  {
    return Ok(());
  }
  let guild_config = sqlx::query_as!(
    Guild,
    "SELECT * FROM guilds WHERE guild_id = $1",
    reaction_remove.guild_id.unwrap().get() as i64
  )
  .fetch_one(&ctx.db)
  .await?;
  if let Some(starboard_id) = guild_config.starboard_channel_id {
    if reaction_remove.channel_id == starboard_id {
      return Ok(());
    }

    let msg = ctx
      .http
      .message(reaction_remove.channel_id, reaction_remove.message_id)
      .await?
      .model()
      .await?;
    let star_count = msg
      .reactions
      .iter()
      .filter(|r| {
        r.emoji
          == ReactionType::Unicode {
            name: "💧".to_owned(),
          }
      })
      .count();
    if star_count < guild_config.min_stars.unwrap() as usize {
      return Ok(());
    }

    if let Some(star_msg) = sqlx::query_as!(
      StarMsg,
      "SELECT * FROM starboard WHERE msg_id = $1",
      reaction_remove.message_id.get() as i64
    )
    .fetch_optional(&ctx.db)
    .await?
    {
      edit_star(ctx, msg, star_count, guild_config, star_msg).await?;
    }
  }
  Ok(())
}

async fn create_star(
  ctx: Arc<BeaContext>,
  msg: Message,
  stars: usize,
  guild_config: Guild,
) -> BeaResult<()> {
  let star_msg = ctx
    .http
    .create_message(Id::new(guild_config.starboard_channel_id.unwrap() as u64))
    .content(&format!(
      "{} **{}** {}",
      star_emoji(stars),
      stars,
      msg.channel_id.mention()
    ))?
    .embeds(&[gen_embed(msg.clone(), stars)?])?
    .components(&[gen_component(msg.clone())])?
    .await?
    .model()
    .await?;

  sqlx::query!(
    "INSERT INTO starboard VALUES($1, $2, $3, $4)",
    msg.id.get() as i64,
    star_msg.guild_id.unwrap().get() as i64,
    star_msg.channel_id.get() as i64,
    star_msg.id.get() as i64
  )
  .execute(&ctx.db)
  .await?;

  Ok(())
}

async fn edit_star(
  ctx: Arc<BeaContext>,
  msg: Message,
  stars: usize,
  guild_config: Guild,
  star_msg: StarMsg,
) -> BeaResult<()> {
  ctx
    .http
    .update_message(
      Id::new(guild_config.starboard_channel_id.unwrap() as u64),
      Id::new(star_msg.starboard_msg_id as u64),
    )
    .content(Some(&format!(
      "{} **{}** {}",
      star_emoji(stars),
      stars,
      msg.channel_id.mention()
    )))?
    .embeds(Some(&[gen_embed(msg.clone(), stars)?]))?
    .components(Some(&[gen_component(msg.clone())]))?
    .await?;

  Ok(())
}

fn gen_component(msg: Message) -> Component {
  Component::ActionRow(ActionRow {
    components: Vec::from([Component::Button(Button {
      custom_id: None,
      disabled: false,
      emoji: None,
      label: Some("Jump to Message".to_owned()),
      style: ButtonStyle::Link,
      url: Some(format!(
        "https://discord.com/channels/{}/{}/{}",
        msg.guild_id.unwrap(),
        msg.channel_id.get(),
        msg.id.get()
      )),
    })]),
  })
}

fn gen_embed(msg: Message, stars: usize) -> BeaResult<Embed> {
  let author = EmbedAuthorBuilder::new(msg.author.clone().name)
    .icon_url(ImageSource::url(&utils::avatar_url(msg.clone())?)?)
    .build();

  let embed = EmbedBuilder::new()
    .author(author)
    .description(msg.content.clone())
    .color(gen_color(stars))
    .timestamp(msg.timestamp);

  let embed = maybe_put_image(embed, msg.clone())?;
  Ok(embed)
}

fn maybe_put_image(embed: EmbedBuilder, msg: Message) -> BeaResult<Embed> {
  Ok(if msg.attachments.iter().count() == 1 {
    embed
      .image(ImageSource::url(msg.attachments[0].clone().proxy_url)?)
      .build()
  } else if msg.attachments.iter().count() > 1 {
    embed
      .description(format!(
        "{}\n\nMessage contained more than 1 attachment",
        msg.content
      ))
      .build()
  } else {
    embed.build()
  })
}

fn gen_color(stars: usize) -> u32 {
  let p = if (stars as f32 / 13.0) > 1.0 {
    1.0
  } else {
    stars as f32 / 13.0
  };
  let red = (0.0 * p + 230.0 * (1.0 - p)).trunc() as u32;
  let green = (162.0 * p - 246.0 * (1.0 - p)).trunc() as u32;
  let blue = 255 as u32;

  (red << 16) + (green << 8) + blue
}

fn star_emoji(count: usize) -> &'static str {
  match count {
    1..=4 => "💧",
    5..=10 => "💦",
    _ => "🌊",
  }
}
