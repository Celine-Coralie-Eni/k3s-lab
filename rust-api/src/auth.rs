use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation, Algorithm};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use once_cell::sync::Lazy;
use std::sync::RwLock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Jwks {
    pub keys: Vec<Jwk>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Jwk {
    pub kid: Option<String>,
    pub kty: String,
    pub n: Option<String>,
    pub e: Option<String>,
}

static JWKS_CACHE: Lazy<RwLock<Option<Jwks>>> = Lazy::new(|| RwLock::new(None));

pub async fn fetch_jwks(jwks_url: &str) -> anyhow::Result<Jwks> {
    let resp = reqwest::get(jwks_url).await?.error_for_status()?;
    let jwks: Jwks = resp.json().await?;
    Ok(jwks)
}

pub async fn get_decoding_key_from_jwks(jwks_url: &str, kid: &str) -> anyhow::Result<DecodingKey> {
    {
        if let Some(cached) = JWKS_CACHE.read().unwrap().clone() {
            if let Some(key) = cached.keys.iter().find(|k| k.kid.as_deref() == Some(kid)) {
                if let (Some(n), Some(e)) = (&key.n, &key.e) {
                    return Ok(DecodingKey::from_rsa_components(n, e));
                }
            }
        }
    }
    let jwks = fetch_jwks(jwks_url).await?;
    {
        *JWKS_CACHE.write().unwrap() = Some(jwks.clone());
    }
    if let Some(key) = jwks.keys.iter().find(|k| k.kid.as_deref() == Some(kid)) {
        if let (Some(n), Some(e)) = (&key.n, &key.e) {
            return Ok(DecodingKey::from_rsa_components(n, e));
        }
    }
    anyhow::bail!("kid not found in JWKS")
}

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

pub async fn verify_token_oidc(token: &str) -> anyhow::Result<Claims> {
    let header = jsonwebtoken::decode_header(token)?;
    let kid = header.kid.ok_or_else(|| anyhow::anyhow!("missing kid"))?;
    let issuer = std::env::var("OIDC_ISSUER").unwrap_or_else(|_| "http://localhost:8088/realms/lab".to_string());
    let jwks_url = std::env::var("OIDC_JWKS_URL").unwrap_or_else(|_| format!("{}/protocol/openid-connect/certs", issuer));
    let mut validation = Validation::new(Algorithm::RS256);
    validation.set_audience(&[]); // optional: set expected audience
    validation.set_issuer(&[issuer.as_str()]);
    let decoding_key = get_decoding_key_from_jwks(&jwks_url, &kid).await?;
    let data = decode::<Claims>(token, &decoding_key, &validation)?;
    Ok(data.claims)
}

pub fn extract_user_id_from_token(token: &str) -> Result<Uuid, Box<dyn std::error::Error>> {
    let claims = verify_token(token)?;
    let user_id = Uuid::parse_str(&claims.sub)?;
    Ok(user_id)
}


