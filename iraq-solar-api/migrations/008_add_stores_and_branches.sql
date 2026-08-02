-- Migration 008: Add stores and store branches, link products, orders, banners, delivery fees, notifications

-- 1. Create stores table
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(150) UNIQUE,
    description TEXT,
    logo_url TEXT,
    cover_url TEXT,
    phone VARCHAR(20),
    email VARCHAR(150),
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    rating NUMERIC(2,1) DEFAULT 0,
    total_ratings INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create store_branches table
CREATE TABLE IF NOT EXISTS store_branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    governorate_id INT REFERENCES governorates(id) ON DELETE SET NULL,
    city VARCHAR(50),
    address TEXT,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Link products to stores and branches
ALTER TABLE products ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES store_branches(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_branch ON products(branch_id);

-- 4. Link orders to stores
ALTER TABLE orders ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_orders_store ON orders(store_id);

-- 5. Link notifications to stores
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_notifications_store ON notifications(store_id);

-- 6. Link store_banners to stores
ALTER TABLE store_banners ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_store_banners_store ON store_banners(store_id);

-- 7. Link delivery_fees to stores
ALTER TABLE delivery_fees ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES stores(id) ON DELETE CASCADE;
ALTER TABLE delivery_fees DROP CONSTRAINT IF EXISTS delivery_fees_merchant_id_governorate_id_key;
ALTER TABLE delivery_fees ADD CONSTRAINT delivery_fees_store_id_governorate_id_key UNIQUE (store_id, governorate_id);
CREATE INDEX IF NOT EXISTS idx_delivery_fees_store ON delivery_fees(store_id);
