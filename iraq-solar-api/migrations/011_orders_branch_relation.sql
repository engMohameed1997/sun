-- Migration 011: Add branch_id to orders + full relational view

-- 1. Add branch_id column to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES store_branches(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_orders_branch ON orders(branch_id);

-- 2. Create helper view: v_orders_full
--    Joins orders with users, stores, store_branches for admin queries
CREATE OR REPLACE VIEW v_orders_full AS
SELECT
    o.id,
    o.user_id,
    o.store_id,
    o.branch_id,
    o.status,
    o.total_amount_iqd,
    o.shipping_address,
    o.payment_method,
    o.payment_status,
    o.created_at,
    o.updated_at,
    -- Customer info
    u.full_name   AS customer_name,
    u.phone       AS customer_phone,
    u.governorate AS customer_governorate,
    u.city        AS customer_city,
    -- Store info
    s.name        AS store_name,
    s.slug        AS store_slug,
    s.logo_url    AS store_logo_url,
    s.phone       AS store_phone,
    -- Branch info
    b.name        AS branch_name,
    b.address     AS branch_address,
    b.city        AS branch_city,
    b.phone       AS branch_phone,
    g.name_ar     AS branch_governorate_ar,
    g.name_en     AS branch_governorate_en
FROM orders o
LEFT JOIN users          u ON o.user_id    = u.id
LEFT JOIN stores         s ON o.store_id   = s.id
LEFT JOIN store_branches b ON o.branch_id  = b.id
LEFT JOIN governorates   g ON b.governorate_id = g.id;

-- 3. Ensure order_items also carries branch_id for per-item store/branch tracking
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES store_branches(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_order_items_branch ON order_items(branch_id);
