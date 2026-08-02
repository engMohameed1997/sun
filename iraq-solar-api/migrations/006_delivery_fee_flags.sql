-- Migration 006: Add active status flag to delivery fees
ALTER TABLE delivery_fees ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;
