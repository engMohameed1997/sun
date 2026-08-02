-- Migration 010: Change USD to IQD and fix products brand

-- 1. Rename price columns in products
ALTER TABLE products RENAME COLUMN price_usd TO price_iqd;

-- 2. Rename price columns in orders
ALTER TABLE orders RENAME COLUMN total_amount_usd TO total_amount_iqd;
ALTER TABLE order_items RENAME COLUMN unit_price_usd TO unit_price_iqd;
ALTER TABLE order_items RENAME COLUMN total_price_usd TO total_price_iqd;

