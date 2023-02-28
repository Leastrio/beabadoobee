use sqlx::{
  postgres::{PgConnectOptions, PgPoolOptions},
  ConnectOptions, PgPool,
};

use std::str::FromStr;

use crate::BeaResult;

pub async fn db_connect(connection_string: &str) -> BeaResult<PgPool> {
  let connection_options = PgConnectOptions::from_str(connection_string)?
    .disable_statement_logging()
    .clone();

  Ok(
    PgPoolOptions::new()
      .max_connections(10)
      .connect_with(connection_options)
      .await?,
  )
}
