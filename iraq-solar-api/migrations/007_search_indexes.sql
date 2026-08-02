-- Migration 007: Performance & Search Indexes with Trigram extension for Arabic search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_brand_trgm ON products USING gin (brand gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_users_fullname_trgm ON users USING gin (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_users_governorate ON users(governorate);
