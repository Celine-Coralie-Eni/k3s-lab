-- Database initialization script
-- This script runs when the PostgreSQL container starts for the first time

-- Create the database if it doesn't exist
SELECT 'CREATE DATABASE k3s_lab_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'k3s_lab_api')\gexec

-- Connect to the database
\c k3s_lab_api;

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create extension for pgcrypto (for password hashing if needed)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Set timezone
SET timezone = 'UTC';

-- Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE k3s_lab_api TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;


