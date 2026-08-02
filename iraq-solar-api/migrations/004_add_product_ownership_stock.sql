-- Migration 004: Add product ownership, soft delete, and reservation stock fields
ALTER TABLE products ADD COLUMN IF NOT EXISTS merchant_id UUID REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE products ADD COLUMN IF NOT EXISTS reserved_quantity INT NOT NULL DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS low_stock_threshold INT NOT NULL DEFAULT 5;

CREATE INDEX IF NOT EXISTS idx_products_merchant ON products(merchant_id);
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON products(deleted_at);
