use actix_web::{dev::Payload, Error as ActixError, FromRequest, HttpRequest};
use futures_util::future::{ready, Ready};

use crate::auth::verify_token_oidc;

#[derive(Clone, Debug)]
pub struct OidcUser {
    pub sub: String,
}

impl FromRequest for OidcUser {
    type Error = ActixError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        let auth = req
            .headers()
            .get("Authorization")
            .and_then(|h| h.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .map(|s| s.to_string());

        let Some(token) = auth else {
            return ready(Err(actix_web::error::ErrorUnauthorized("missing bearer token")));
        };

        // Note: actix extractors are sync; for simplicity, do quick verify in blocking fashion via tokio handle
        // In production, implement a proper async extractor.
        let res = tokio::runtime::Handle::current().block_on(async move {
            verify_token_oidc(&token).await
        });

        match res {
            Ok(claims) => ready(Ok(OidcUser { sub: claims.sub })),
            Err(_) => ready(Err(actix_web::error::ErrorUnauthorized("invalid token"))),
        }
    }
}


