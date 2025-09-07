-- Drop triggers
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS idx_tasks_completed;
DROP INDEX IF EXISTS idx_tasks_user_id;
DROP INDEX IF EXISTS idx_users_email;

-- Drop tables
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS users;


