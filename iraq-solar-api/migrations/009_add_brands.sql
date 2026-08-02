-- Migration 009: Add brands table and relate to products

-- 1. Create brands table
CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add brand_id to products
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;

-- 3. Data Migration: Move existing distinct text brands to the new brands table
INSERT INTO brands (name)
SELECT DISTINCT brand FROM products WHERE brand IS NOT NULL AND brand != ''
ON CONFLICT (name) DO NOTHING;

-- 4. Link products to their new brand_ids
UPDATE products p
SET brand_id = b.id
FROM brands b
WHERE p.brand = b.name;

-- 5. Drop the old string brand column
ALTER TABLE products DROP COLUMN IF EXISTS brand;

CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id);
