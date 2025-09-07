use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse, Responder};
use bcrypt::{hash, DEFAULT_COST};
use diesel::prelude::*;
use log::error;
use serde_json::json;
use uuid::Uuid;
use validator::Validate;

use crate::{
    auth::extract_user_id_from_token,
    models::{CreateUserRequest, NewUser, UpdateUserRequest, User, UserResponse},
    schema::users,
    DbPool,
};

// Helper function to extract user ID from Authorization header
fn get_current_user_id(req: &HttpRequest) -> Result<Uuid, HttpResponse> {
    let auth_header = req
        .headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .and_then(|h| h.strip_prefix("Bearer "));

    match auth_header {
        Some(token) => {
            extract_user_id_from_token(token).map_err(|_| {
                HttpResponse::Unauthorized().json(json!({
                    "error": "Invalid or expired token"
                }))
            })
        }
        None => Err(HttpResponse::Unauthorized().json(json!({
            "error": "Authorization header required"
        }))),
    }
}

#[get("/")]
pub async fn get_users(pool: web::Data<DbPool>, req: HttpRequest) -> impl Responder {
    let _current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };

    let conn = &mut pool.get().expect("Failed to get DB connection");

    let all_users: Vec<User> = match users::table.load(conn) {
        Ok(users) => users,
        Err(e) => {
            error!("Failed to fetch users: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to fetch users"
            }));
        }
    };

    let user_responses: Vec<UserResponse> = all_users.into_iter().map(|u| u.into()).collect();

    HttpResponse::Ok().json(json!({
        "users": user_responses
    }))
}

#[get("/{id}")]
pub async fn get_user(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let _current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let user_id = path.into_inner();

    let conn = &mut pool.get().expect("Failed to get DB connection");

    let user: User = match users::table
        .filter(users::id.eq(user_id))
        .first(conn)
    {
        Ok(user) => user,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "User not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch user: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to fetch user"
            }));
        }
    };

    let user_response: UserResponse = user.into();
    HttpResponse::Ok().json(json!({
        "user": user_response
    }))
}

#[post("/")]
pub async fn create_user(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    user_data: web::Json<CreateUserRequest>,
) -> impl Responder {
    let _current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };

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
                "error": "Failed to process user creation"
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

    let user_response: UserResponse = user.into();
    HttpResponse::Created().json(json!({
        "message": "User created successfully",
        "user": user_response
    }))
}

#[put("/{id}")]
pub async fn update_user(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
    user_data: web::Json<UpdateUserRequest>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let user_id = path.into_inner();

    // Only allow users to update their own profile
    if current_user_id != user_id {
        return HttpResponse::Forbidden().json(json!({
            "error": "You can only update your own profile"
        }));
    }

    // Validate input
    if let Err(validation_errors) = user_data.validate() {
        return HttpResponse::BadRequest().json(json!({
            "error": "Validation failed",
            "details": validation_errors
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Check if user exists
    let existing_user: User = match users::table
        .filter(users::id.eq(user_id))
        .first(conn)
    {
        Ok(user) => user,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "User not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch user: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to update user"
            }));
        }
    };

    // Update user
    let updated_user: User = match diesel::update(users::table.filter(users::id.eq(user_id)))
        .set((
            user_data.username.as_ref().map(|u| users::username.eq(u)),
            user_data.email.as_ref().map(|e| users::email.eq(e)),
        ))
        .get_result(conn)
    {
        Ok(user) => user,
        Err(e) => {
            error!("Failed to update user: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to update user"
            }));
        }
    };

    let user_response: UserResponse = updated_user.into();
    HttpResponse::Ok().json(json!({
        "message": "User updated successfully",
        "user": user_response
    }))
}

#[delete("/{id}")]
pub async fn delete_user(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let user_id = path.into_inner();

    // Only allow users to delete their own account
    if current_user_id != user_id {
        return HttpResponse::Forbidden().json(json!({
            "error": "You can only delete your own account"
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Check if user exists
    let existing_user: User = match users::table
        .filter(users::id.eq(user_id))
        .first(conn)
    {
        Ok(user) => user,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "User not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch user: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to delete user"
            }));
        }
    };

    // Delete user
    match diesel::delete(users::table.filter(users::id.eq(user_id))).execute(conn) {
        Ok(_) => HttpResponse::Ok().json(json!({
            "message": "User deleted successfully"
        })),
        Err(e) => {
            error!("Failed to delete user: {}", e);
            HttpResponse::InternalServerError().json(json!({
                "error": "Failed to delete user"
            }))
        }
    }
}
