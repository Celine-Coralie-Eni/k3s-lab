use diesel::pg::PgConnection;
use diesel::r2d2::{self, ConnectionManager};
use diesel::Connection;
use diesel_migrations::{embed_migrations, EmbeddedMigrations, MigrationHarness};
use log::info;

pub type DbPool = r2d2::Pool<ConnectionManager<PgConnection>>;

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!();

pub fn establish_connection(database_url: &str) -> PgConnection {
    PgConnection::establish(database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url))
}

pub fn run_migrations(pool: &DbPool) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let conn = &mut pool.get().expect("Failed to get DB connection");
    
    info!("Running database migrations...");
    
    conn.run_pending_migrations(MIGRATIONS)?;
    
    info!("Database migrations completed successfully");
    Ok(())
}
