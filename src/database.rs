use sqlx::{
    query,
    sqlite::{SqliteConnectOptions, SqlitePoolOptions},
    types::time::OffsetDateTime,
    Pool, Row, Sqlite, SqlitePool,
};
use std::convert::From;
use std::str::FromStr;

#[derive(Debug, Default)]
pub struct Event {
    #[allow(dead_code)]
    pub id: Option<i32>,
    pub actor_id: Vec<u8>,
    pub kind: String,
    pub url: String,
    pub referrer: Option<String>,
    pub search: Option<String>,
    #[allow(dead_code)]
    pub timestamp: Option<OffsetDateTime>,
}

#[derive(Debug, Default)]
pub struct Actor {
    pub id: Vec<u8>,
    pub country: Option<String>,
    pub city: Option<String>,
    pub user_agent_id: Option<i64>,
    #[allow(dead_code)]
    pub timestamp: Option<OffsetDateTime>,
}

#[derive(Debug, Default)]
pub struct UserAgent {
    #[allow(dead_code)]
    pub id: Option<i32>,
    pub name: Option<String>,
    pub category: Option<String>,
    pub os: Option<String>,
    pub os_version: Option<String>,
    pub browser_type: Option<String>,
    pub version: Option<String>,
    pub vendor: Option<String>,
}

impl From<woothee::parser::WootheeResult<'_>> for UserAgent {
    fn from(woothee: woothee::parser::WootheeResult<'_>) -> UserAgent {
        fn parse(v: impl ToString) -> Option<String> {
            let v = v.to_string();
            if v.is_empty() {
                return None;
            }
            if v == "UNKNOWN" {
                return None;
            }
            Some(v)
        }

        UserAgent {
            name: parse(woothee.name),
            category: parse(woothee.category),
            os: parse(woothee.os),
            os_version: parse(woothee.os_version),
            browser_type: parse(woothee.browser_type),
            version: parse(woothee.version),
            vendor: parse(woothee.vendor),
            ..Default::default()
        }
    }
}

pub async fn init_db_pool(db_url: &str) -> Result<Pool<Sqlite>, sqlx::Error> {
    let options = SqliteConnectOptions::from_str(db_url)?.create_if_missing(true);
    let pool = SqlitePoolOptions::new().connect_with(options).await?;

    sqlx::migrate!().run(&pool).await?;
    Ok(pool)
}

pub async fn store_actor(pool: &SqlitePool, actor: &Actor) -> Result<(), sqlx::Error> {
    query(
        "INSERT OR IGNORE INTO actors (id, country, city, user_agent_id)
        VALUES (?, ?, ?, ?)",
    )
    .bind(actor.id.clone())
    .bind(actor.country.clone())
    .bind(actor.city.clone())
    .bind(actor.user_agent_id)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn store_event(pool: &SqlitePool, event: &Event) -> Result<i64, sqlx::Error> {
    let result = query(
        "INSERT INTO events (actor_id, kind, url, referrer, search)
         VALUES (?, ?, ?, ?, ?)
         RETURNING id",
    )
    .bind(event.actor_id.clone())
    .bind(event.kind.clone())
    .bind(event.url.clone())
    .bind(event.referrer.clone())
    .bind(event.search.clone())
    .fetch_one(pool)
    .await?;

    let id = result.get("id");
    Ok(id)
}

pub async fn store_user_agent(
    pool: &SqlitePool,
    user_agent: &UserAgent,
) -> Result<i64, sqlx::Error> {
    let result = query(
        "INSERT INTO user_agents (name, category, os, os_version, browser_type, version, vendor)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         RETURNING id",
    )
    .bind(user_agent.name.clone())
    .bind(user_agent.category.clone())
    .bind(user_agent.os.clone())
    .bind(user_agent.os_version.clone())
    .bind(user_agent.browser_type.clone())
    .bind(user_agent.version.clone())
    .bind(user_agent.vendor.clone())
    .fetch_one(pool)
    .await?;

    let id = result.get("id");
    Ok(id)
}
