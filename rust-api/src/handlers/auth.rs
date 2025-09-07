use actix_web::{post, web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use diesel::prelude::*;
use log::error;
use serde_json::json;
use validator::Validate;

use crate::{
    auth::create_token,
    models::{CreateUserRequest, LoginRequest, NewUser, User, AuthResponse, UserResponse},
    schema::users,
    DbPool,
};

#[post("/register")]
pub async fn register(
    pool: web::Data<DbPool>,
    user_data: web::Json<CreateUserRequest>,
) -> impl Responder {
    // Validate input
    if let Err(validation_errors) = user_data.validate() {
        return HttpResponse::BadRequest().json(json!({
            "error": "Validation failed",
            "details": validation_errors
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Check if user already exists
    let existing_user: Result<User, diesel::result::Error> = users::table
        .filter(users::email.eq(&user_data.email))
        .first(conn);

    if existing_user.is_ok() {
        return HttpResponse::Conflict().json(json!({
            "error": "User with this email already exists"
        }));
    }

    // Hash password
    let password_hash = match hash(&user_data.password, DEFAULT_COST) {
        Ok(hash) => hash,
        Err(_) => {
            error!("Failed to hash password");
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to process registration"
            }));
        }
    };

    // Create new user
    let new_user = NewUser {
        username: user_data.username.clone(),
        email: user_data.email.clone(),
        password_hash,
    };

    let user: User = match diesel::insert_into(users::table)
        .values(&new_user)
        .get_result(conn)
    {
        Ok(user) => user,
        Err(e) => {
            error!("Failed to create user: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to create user"
            }));
        }
    };

    // Generate JWT token
    let token = match create_token(user.id) {
        Ok(token) => token,
        Err(e) => {
            error!("Failed to create token: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to create authentication token"
            }));
        }
    };

    let auth_response = AuthResponse {
        token,
        user: user.into(),
    };

    HttpResponse::Created().json(json!({
        "message": "User registered successfully",
        "token": auth_response.token,
        "user": auth_response.user
    }))
}

#[post("/login")]
pub async fn login(
    pool: web::Data<DbPool>,
    login_data: web::Json<LoginRequest>,
) -> impl Responder {
    // Validate input
    if let Err(validation_errors) = login_data.validate() {
        return HttpResponse::BadRequest().json(json!({
            "error": "Validation failed",
            "details": validation_errors
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Find user by email
    let user: User = match users::table
        .filter(users::email.eq(&login_data.email))
        .first(conn)
    {
        Ok(user) => user,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::Unauthorized().json(json!({
                "error": "Invalid email or password"
            }));
        }
        Err(e) => {
            error!("Database error during login: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to process login"
            }));
        }
    };

    // Verify password
    if !verify(&login_data.password, &user.password_hash).unwrap_or(false) {
        return HttpResponse::Unauthorized().json(json!({
            "error": "Invalid email or password"
        }));
    }

    // Generate JWT token
    let token = match create_token(user.id) {
        Ok(token) => token,
        Err(e) => {
            error!("Failed to create token: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to create authentication token"
            }));
        }
    };

    let auth_response = AuthResponse {
        token,
        user: user.into(),
    };

    HttpResponse::Ok().json(json!({
        "message": "Login successful",
        "token": auth_response.token,
        "user": auth_response.user
    }))
}
