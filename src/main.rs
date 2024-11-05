mod signal;

use axum::Router;
use axum_credible::{download_geo_db, get_stats_router, init_db_pool};
use dotenvy::dotenv;
use signal::shutdown_signal;
use std::{error::Error, net::SocketAddr};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error + 'static>> {
    dotenv().ok();
    tracing_subscriber::fmt::init();

    // Read environment variables
    let analytics_key = std::env::var("ANALYTICS_KEY").unwrap_or("/data/analytics.key".to_string());
    let db_url = std::env::var("DATABASE_URL").unwrap_or("sqlite:///data/stats.db".to_string());
    let geo_db_path =
        std::env::var("GEO_DB_PATH").unwrap_or("/data/GeoLite2-City.mmdb".to_string());
    let geo_db_account_id = std::env::var("GEO_DB_ACCOUNT_ID").unwrap();
    let geo_db_license_key = std::env::var("GEO_DB_LICENSE_KEY").unwrap();

    // Initialize the database pool
    let pool = init_db_pool(&db_url).await?;

    // Download the GeoLite2 database
    download_geo_db(&geo_db_account_id, &geo_db_license_key, &geo_db_path).await?;

    // Get the stats router and key rotation handle
    let (stats_router, key_rotate_handle) = get_stats_router(&pool, &analytics_key, &geo_db_path);

    let app = Router::new().nest_service("/stats", stats_router);

    let host = "0.0.0.0";
    let port = "3000";
    println!("Listening on {host}:{port}");
    let listener = tokio::net::TcpListener::bind(&format!("{host}:{port}"))
        .await
        .unwrap();
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal(key_rotate_handle.abort_handle()))
    .await?;
    Ok(())
}
