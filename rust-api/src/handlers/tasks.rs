use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse, Responder};
use diesel::prelude::*;
use log::error;
use serde_json::json;
use uuid::Uuid;
use validator::Validate;

use crate::{
    auth::extract_user_id_from_token,
    models::{CreateTaskRequest, NewTask, Task, TaskResponse, UpdateTaskRequest},
    schema::tasks,
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

#[get("")]
pub async fn get_tasks(pool: web::Data<DbPool>, req: HttpRequest) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };

    let conn = &mut pool.get().expect("Failed to get DB connection");

    let user_tasks: Vec<Task> = match tasks::table
        .filter(tasks::user_id.eq(current_user_id))
        .load(conn)
    {
        Ok(tasks) => tasks,
        Err(e) => {
            error!("Failed to fetch tasks: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to fetch tasks"
            }));
        }
    };

    let task_responses: Vec<TaskResponse> = user_tasks.into_iter().map(|t| t.into()).collect();

    HttpResponse::Ok().json(json!({
        "tasks": task_responses
    }))
}

#[get("/{id}")]
pub async fn get_task(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let task_id = path.into_inner();

    let conn = &mut pool.get().expect("Failed to get DB connection");

    let task: Task = match tasks::table
        .filter(tasks::id.eq(task_id))
        .filter(tasks::user_id.eq(current_user_id))
        .first(conn)
    {
        Ok(task) => task,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "Task not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch task: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to fetch task"
            }));
        }
    };

    let task_response: TaskResponse = task.into();
    HttpResponse::Ok().json(json!({
        "task": task_response
    }))
}

#[post("")]
pub async fn create_task(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    task_data: web::Json<CreateTaskRequest>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };

    // Validate input
    if let Err(validation_errors) = task_data.validate() {
        return HttpResponse::BadRequest().json(json!({
            "error": "Validation failed",
            "details": validation_errors
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    let new_task = NewTask {
        title: task_data.title.clone(),
        description: task_data.description.clone(),
        user_id: current_user_id,
    };

    let task: Task = match diesel::insert_into(tasks::table)
        .values(&new_task)
        .get_result(conn)
    {
        Ok(task) => task,
        Err(e) => {
            error!("Failed to create task: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to create task"
            }));
        }
    };

    let task_response: TaskResponse = task.into();
    HttpResponse::Created().json(json!({
        "message": "Task created successfully",
        "task": task_response
    }))
}

#[put("/{id}")]
pub async fn update_task(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
    task_data: web::Json<UpdateTaskRequest>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let task_id = path.into_inner();

    // Validate input
    if let Err(validation_errors) = task_data.validate() {
        return HttpResponse::BadRequest().json(json!({
            "error": "Validation failed",
            "details": validation_errors
        }));
    }

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Check if task exists and belongs to user
    let existing_task: Task = match tasks::table
        .filter(tasks::id.eq(task_id))
        .filter(tasks::user_id.eq(current_user_id))
        .first(conn)
    {
        Ok(task) => task,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "Task not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch task: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to update task"
            }));
        }
    };

    // Update task
    let updated_task: Task = match diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
        .set((
            task_data.title.as_ref().map(|t| tasks::title.eq(t)),
            task_data.description.as_ref().map(|d| tasks::description.eq(d)),
            task_data.completed.as_ref().map(|c| tasks::completed.eq(c)),
        ))
        .get_result(conn)
    {
        Ok(task) => task,
        Err(e) => {
            error!("Failed to update task: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to update task"
            }));
        }
    };

    let task_response: TaskResponse = updated_task.into();
    HttpResponse::Ok().json(json!({
        "message": "Task updated successfully",
        "task": task_response
    }))
}

#[delete("/{id}")]
pub async fn delete_task(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let current_user_id = match get_current_user_id(&req) {
        Ok(id) => id,
        Err(response) => return response,
    };
    let task_id = path.into_inner();

    let conn = &mut pool.get().expect("Failed to get DB connection");

    // Check if task exists and belongs to user
    let existing_task: Task = match tasks::table
        .filter(tasks::id.eq(task_id))
        .filter(tasks::user_id.eq(current_user_id))
        .first(conn)
    {
        Ok(task) => task,
        Err(diesel::result::Error::NotFound) => {
            return HttpResponse::NotFound().json(json!({
                "error": "Task not found"
            }));
        }
        Err(e) => {
            error!("Failed to fetch task: {}", e);
            return HttpResponse::InternalServerError().json(json!({
                "error": "Failed to delete task"
            }));
        }
    };

    // Delete task
    match diesel::delete(tasks::table.filter(tasks::id.eq(task_id))).execute(conn) {
        Ok(_) => HttpResponse::Ok().json(json!({
            "message": "Task deleted successfully"
        })),
        Err(e) => {
            error!("Failed to delete task: {}", e);
            HttpResponse::InternalServerError().json(json!({
                "error": "Failed to delete task"
            }))
        }
    }
}
