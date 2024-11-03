use crate::crypto::{get_cryptographic_key, rotate_cryptographic_key};
use crate::{database, geo_locate::geoip_lookup};
use axum::extract::ConnectInfo;
use axum::extract::{Json, State};
use axum::response::Html;
use axum::{
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use chrono::{Datelike, TimeZone};
use http::{HeaderMap, StatusCode};
use sqlx::query_scalar;
use std::error::Error;
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone)]
pub struct AppState {
    pub pool: sqlx::SqlitePool,
    pub db_path: String,
    pub analytics_secret: Arc<Mutex<Vec<u8>>>,
}

#[derive(serde::Deserialize, Debug)]
pub struct StatsEvent {
    #[serde(rename = "n")]
    pub name: String,
    #[serde(rename = "u")]
    pub location: String,
    #[allow(dead_code)]
    #[serde(rename = "d")]
    pub domain: String,
    #[serde(rename = "r")]
    pub referrer: Option<String>,
}

fn generate_visitor_id(ip: &str, user_agent: &str, salt: &[u8]) -> Vec<u8> {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(ip);
    hasher.update(user_agent);
    hasher.update(salt);
    hasher.finalize().to_vec()
}

async fn get_ip(headers: &HeaderMap, socket_addr: &ConnectInfo<SocketAddr>) -> String {
    let ip_from_headers = match headers.get("X-Forwarded-For") {
        Some(ip) => match ip.to_str() {
            Ok(ip) => Some(ip.to_string()),
            _ => None,
        },
        _ => None,
    };

    match ip_from_headers {
        Some(ip) => ip,
        _ => socket_addr.ip().to_string(),
    }
}

async fn get_user_agent_id(
    headers: &HeaderMap,
    pool: &sqlx::SqlitePool,
) -> Result<(Option<i64>, Option<String>), Box<dyn Error>> {
    use crate::database;

    match headers.get("User-Agent") {
        None => Ok((None, None)),
        Some(user_agent) => {
            let parser = woothee::parser::Parser::new();
            let user_agent = user_agent.to_str().unwrap_or_default();
            match parser.parse(user_agent) {
                None => Ok((None, Some(user_agent.to_string()))),
                Some(result) => {
                    let id = database::store_user_agent(pool, &result.into()).await?;
                    Ok((Some(id), Some(user_agent.to_string())))
                }
            }
        }
    }
}

pub async fn stats_handler() -> impl IntoResponse {
    let one_year_in_secs = 60 * 60 * 24 * 365;
    let cache_control_header = format!("public, max-age={}", one_year_in_secs);
    let headers = HeaderMap::from_iter(vec![
        (
            http::header::CONTENT_TYPE,
            "text/javascript".parse().unwrap(),
        ),
        (
            http::header::CACHE_CONTROL,
            cache_control_header.parse().unwrap(),
        ),
    ]);
    let stats_script = include_str!("../static/script.js");

    use minify_js::{minify, Session, TopLevelMode};
    let session = Session::new();
    let mut out = Vec::new();
    minify(
        &session,
        TopLevelMode::Global,
        stats_script.as_bytes(),
        &mut out,
    )
    .unwrap();
    (headers, out)
}

async fn event_handler(
    State(state): State<AppState>,
    headers: HeaderMap,
    connect_info: ConnectInfo<SocketAddr>,
    Json(payload): Json<StatsEvent>,
) -> impl IntoResponse {
    let ip = get_ip(&headers, &connect_info).await;
    if ip.is_empty() {
        return StatusCode::INTERNAL_SERVER_ERROR;
    }

    let Ok((user_agent_id, user_agent)) = get_user_agent_id(&headers, &state.pool).await else {
        return StatusCode::INTERNAL_SERVER_ERROR;
    };

    let (country, city) = match geoip_lookup(&ip, &state.db_path) {
        Ok((country, city)) => (country, city),
        Err(_) => (None, None),
    };

    let actor_id = generate_visitor_id(
        &ip,
        &user_agent.unwrap_or_default(),
        &state.analytics_secret.lock().unwrap(),
    );

    let Ok(()) = database::store_actor(
        &state.pool,
        &database::Actor {
            id: actor_id.clone(),
            country,
            city,
            user_agent_id,
            ..Default::default()
        },
    )
    .await
    else {
        return StatusCode::INTERNAL_SERVER_ERROR;
    };

    let Ok(_id) = database::store_event(
        &state.pool,
        &database::Event {
            actor_id,
            kind: payload.name,
            url: payload.location,
            referrer: payload.referrer,
            ..Default::default()
        },
    )
    .await
    else {
        return StatusCode::INTERNAL_SERVER_ERROR;
    };

    StatusCode::OK
}

async fn handler(State(state): State<AppState>) -> impl IntoResponse {
    let visitors = query_scalar!("SELECT COUNT(id) FROM actors")
        .fetch_one(&state.pool)
        .await
        .unwrap();
    let pageviews = query_scalar!("SELECT COUNT(id) FROM events")
        .fetch_one(&state.pool)
        .await
        .unwrap();
    Html(format!(
        r#"
<html>
    <head>
        <script defer data-domain="domain.test" src="/stats/script.js"></script>
    </head>

    <body>
        <h1>Test</h1>
        <ul>
            <li>Users: {visitors}</li>
            <li>Pageviews: {pageviews}</li>
        </ul>
    </body>
</html>
    "#
    ))
}

pub fn get_stats_router(
    pool: &sqlx::SqlitePool,
    analytics_key: &str,
    geo_db_path: &str,
) -> (Router, tokio::task::JoinHandle<()>) {
    let analytics_key = analytics_key.to_string();
    let geo_db_path = geo_db_path.to_string();

    // Load from file or initialize a new key
    let analytics_secret = Arc::new(Mutex::new(get_cryptographic_key(&analytics_key).unwrap()));

    // Rotate the key at 3am every day
    let rotate_stats_key_task = {
        let mut every_day = {
            let now = chrono::Local::now();
            let target = chrono::Local
                .with_ymd_and_hms(now.year(), now.month(), now.day(), 3, 0, 0)
                .unwrap();
            let target = if target > now {
                target
            } else {
                target + chrono::Duration::days(1)
            };
            let duration_until_3 = target.signed_duration_since(now).to_std().unwrap();
            let start = tokio::time::Instant::now() + duration_until_3;
            tokio::time::interval_at(start, std::time::Duration::from_secs(60 * 60 * 24))
        };

        let analytics_secret = Arc::clone(&analytics_secret);
        tokio::task::spawn(async move {
            loop {
                every_day.tick().await;
                if let Ok(mut key) = analytics_secret.lock() {
                    *key = rotate_cryptographic_key(&analytics_key).unwrap();
                }
            }
        })
    };

    let router = Router::new()
        .route("/script.js", get(stats_handler))
        .route("/event", post(event_handler))
        .route("/summary", get(handler))
        .with_state(AppState {
            analytics_secret,
            db_path: geo_db_path,
            pool: pool.clone(),
        });

    (router, rotate_stats_key_task)
}
