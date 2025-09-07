use chrono::{DateTime, Utc};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::schema::{tasks, users};

#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Identifiable)]
#[diesel(table_name = users)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = users)]
pub struct NewUser {
    pub username: String,
    pub email: String,
    pub password_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(length(min = 3, max = 50))]
    pub username: String,
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 8))]
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct UpdateUserRequest {
    #[validate(length(min = 3, max = 50))]
    pub username: Option<String>,
    #[validate(email)]
    pub email: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserResponse,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            username: user.username,
            email: user.email,
            created_at: user.created_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Identifiable, Associations)]
#[diesel(belongs_to(User))]
#[diesel(table_name = tasks)]
pub struct Task {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub completed: bool,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = tasks)]
pub struct NewTask {
    pub title: String,
    pub description: Option<String>,
    pub user_id: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct CreateTaskRequest {
    #[validate(length(min = 1, max = 200))]
    pub title: String,
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct UpdateTaskRequest {
    #[validate(length(min = 1, max = 200))]
    pub title: Option<String>,
    pub description: Option<String>,
    pub completed: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskResponse {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub completed: bool,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<Task> for TaskResponse {
    fn from(task: Task) -> Self {
        Self {
            id: task.id,
            title: task.title,
            description: task.description,
            completed: task.completed,
            user_id: task.user_id,
            created_at: task.created_at,
            updated_at: task.updated_at,
        }
    }
}


