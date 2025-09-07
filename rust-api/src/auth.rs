use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // User ID
    pub exp: i64,    // Expiration time
    pub iat: i64,    // Issued at
}

impl Claims {
    pub fn new(user_id: Uuid) -> Self {
        let now = Utc::now();
        Self {
            sub: user_id.to_string(),
            exp: (now + Duration::hours(24)).timestamp(),
            iat: now.timestamp(),
        }
    }
}

pub fn create_token(user_id: Uuid) -> Result<String, jsonwebtoken::errors::Error> {
    let claims = Claims::new(user_id);
    let secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

pub fn verify_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )
    .map(|data| data.claims)
}

pub fn extract_user_id_from_token(token: &str) -> Result<Uuid, Box<dyn std::error::Error>> {
    let claims = verify_token(token)?;
    let user_id = Uuid::parse_str(&claims.sub)?;
    Ok(user_id)
}


