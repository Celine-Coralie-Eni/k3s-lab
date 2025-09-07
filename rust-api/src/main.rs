use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer, HttpResponse, Responder};
use diesel::pg::PgConnection;
use diesel::r2d2::{self, ConnectionManager};
use dotenvy::dotenv;
use log::info;

mod auth;
mod db;
mod handlers;
mod models;
mod schema;

pub type DbPool = r2d2::Pool<ConnectionManager<PgConnection>>;

// Simple health check handler
async fn health_check() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "message": "K3s Lab API is running"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env_logger::init();

    info!("Starting K3s Lab API server...");

    // Database connection pool
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let manager = ConnectionManager::<PgConnection>::new(database_url);
    let pool = r2d2::Pool::builder()
        .build(manager)
        .expect("Failed to create pool");

    // Run database migrations
    db::run_migrations(&pool).expect("Failed to run migrations");

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_address = format!("0.0.0.0:{}", port);

    info!("Server running on http://{}", bind_address);

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(Logger::default())
            .wrap(cors)
            .app_data(web::Data::new(pool.clone()))
            .route("/health", web::get().to(health_check))
            .route("/", web::get().to(|| async { 
                HttpResponse::Ok().json(serde_json::json!({
                    "message": "Welcome to K3s Lab API",
                    "version": "1.0.0",
                    "endpoints": {
                        "health": "/health",
                        "api": "/api/*"
                    }
                }))
            }))
    })
    .bind(bind_address)?
    .run()
    .await
}
