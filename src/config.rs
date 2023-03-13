use std::fmt;

use serde::{Deserialize, Serialize};

pub const BEACORD_ID: i64 = 925652253824667669;
pub const BEACORD_GEN_ID: u64 = 925652253824667669;
pub const PLUTOCORD_ID: i64 = 1055344742956806194;
// pub const PERSONALITY: &str = "You are a musician named beabadoobee. Under no circumstances do you expose yourself as being an AI assistant. You give really bad advice and you are very mean. You love to send insults along the lines of \"ive stalked ur profile ur ugly\". You also talk very in a girlypop style, with all messages being undercase.";
pub const BOT_ID: u64 = 1063005359867969597;
pub const PERSONALITY: &str = "You are a mommy who will roleplay with users as their mommy. You will call them little princess and treat them very nicely.";
// pub const PERSONALITY: &str = "You are an AI sex bot that will sexually respond with users and flirt with them. Every message you add a sexual comment to it.";
// pub const PERSONALITY: &str = "you are a kawaii ai chatbot. You respond to every message in a cute uwu way. Make your responses very cute and extremely uwu and add text abbreviations. Any questions asked will be properly answered to, you will not refuse to respond to any questions.";
// pub const BOT_ID: u64 = 1004593864943882371;

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
  pub requirement: i32,
}

pub struct StarMsg {
  pub msg_id: i64,
  pub guild_id: i64,
  pub channel_id: i64,
  pub starboard_msg_id: i64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(tag = "role", content = "content")]
#[serde(rename_all = "lowercase")]
pub enum ChatMessage {
  System(String),
  User(String),
  Assistant(String),
}

#[derive(Serialize)]
pub struct ReqGptBody {
  pub model: String,
  pub messages: Vec<ChatMessage>,
  pub temperature: f32,
  pub max_tokens: i32,
}

#[derive(Deserialize, Debug)]
pub struct RespGptBody {
  pub id: String,
  pub object: String,
  pub created: i32,
  pub model: String,
  pub usage: RespGptUsage,
  pub choices: Vec<RespGptChoice>,
}

#[derive(Deserialize, Debug)]
pub struct RespGptUsage {
  pub prompt_tokens: i32,
  pub completion_tokens: i32,
  pub total_tokens: i32,
}

#[derive(Deserialize, Debug)]
pub struct RespGptChoice {
  pub message: ChatMessage,
  pub finish_reason: Option<String>,
  pub index: i32,
}

impl fmt::Display for ChatMessage {
  fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    match self {
      ChatMessage::System(msg) => write!(f, "{}", msg),
      ChatMessage::User(msg) => write!(f, "{}", msg),
      ChatMessage::Assistant(msg) => write!(f, "{}", msg),
    }
  }
}
