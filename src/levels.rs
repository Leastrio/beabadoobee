use std::sync::Arc;

use twilight_model::gateway::payload::incoming::MessageCreate;

use crate::{context::BeaContext, BeaResult};

pub async fn handle(ctx: Arc<BeaContext>, msg: &MessageCreate) -> BeaResult<()> {
  Ok(())
}