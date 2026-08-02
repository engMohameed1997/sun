-- Migration 003: Add store verification fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_verified ON users(is_verified) WHERE role = 'merchant';
