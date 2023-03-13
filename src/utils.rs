use twilight_model::channel::Message;

use crate::BeaResult;

pub fn avatar_url(msg: Message) -> BeaResult<String> {
  Ok(match msg.member {
    Some(member) => {
      format!(
        "https://cdn.discordapp.com/guilds/{0}/users/{1}/avatars/{2}.png",
        msg.guild_id.unwrap(),
        msg.author.id,
        member.avatar.unwrap_or(msg.author.avatar.unwrap())
      )
    }
    None => {
      format!(
        "https://cdn.discordapp.com/avatars/{0}/{1}.png",
        msg.author.id,
        msg.author.avatar.unwrap()
      )
    }
  })
}
