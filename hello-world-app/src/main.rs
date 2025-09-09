use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Serialize)]
struct Message { message: String }

async fn root() -> Json<Message> {
    Json(Message { message: "Hello, World!".to_string() })
}

#[tokio::main]
async fn main() {
    tracing_subscriber::Registry::default()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let app = Router::new().route("/", get(root));
    let addr: SocketAddr = ([0, 0, 0, 0], 8080).into();
    tracing::info!("listening", %addr);
    axum::serve(tokio::net::TcpListener::bind(addr).await.unwrap(), app)
        .await
        .unwrap();
}
