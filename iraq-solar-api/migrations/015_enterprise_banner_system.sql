-- Migration 015: Enterprise Banner Management System (Tables & Migration)

-- 1. Create banners table (no placement_slot, using timezone and versioned JSONB targeting)
CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_url TEXT NOT NULL,
    mobile_image_url TEXT,
    priority INT DEFAULT 0 CHECK (priority >= 0 AND priority <= 100),
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    action_type VARCHAR(50) DEFAULT 'none',
    action_payload JSONB DEFAULT '{}',
    targeting_rules JSONB DEFAULT '{"version": 1}',
    recurrence_type VARCHAR(20) DEFAULT 'none',
    recurrence_time VARCHAR(10),
    recurrence_end TIMESTAMPTZ,
    timezone VARCHAR(50) DEFAULT 'Asia/Baghdad',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create banner_placements table
CREATE TABLE IF NOT EXISTS banner_placements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
    placement VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(banner_id, placement)
);

-- 3. Create banner_stores table
CREATE TABLE IF NOT EXISTS banner_stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES store_branches(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create banner_events table
CREATE TABLE IF NOT EXISTS banner_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
    event_type VARCHAR(20) NOT NULL, -- 'impression', 'click'
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    device_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create banner_analytics_summary table
CREATE TABLE IF NOT EXISTS banner_analytics_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    impressions INT DEFAULT 0,
    clicks INT DEFAULT 0,
    unique_views INT DEFAULT 0,
    unique_clicks INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(banner_id, date)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_banners_active_priority ON banners(is_active, priority DESC, display_order ASC);
CREATE INDEX IF NOT EXISTS idx_banners_merchant ON banners(merchant_id);
CREATE INDEX IF NOT EXISTS idx_banner_placements_placement ON banner_placements(placement);
CREATE INDEX IF NOT EXISTS idx_banner_stores_store ON banner_stores(store_id);
CREATE INDEX IF NOT EXISTS idx_banner_events_banner ON banner_events(banner_id, event_type);
CREATE INDEX IF NOT EXISTS idx_banner_analytics_summary_banner_date ON banner_analytics_summary(banner_id, date);

-- 6. Data Migration from legacy home_banners and store_banners (if they exist)
DO $$
BEGIN
    -- Migrate home_banners into banners + banner_placements (placement = 'home')
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'home_banners') THEN
        INSERT INTO banners (id, image_url, display_order, is_active, starts_at, ends_at, action_type, action_payload, created_at)
        SELECT 
            hb.id,
            hb.image_url,
            hb.display_order,
            hb.is_active,
            hb.starts_at,
            hb.ends_at,
            CASE WHEN hb.link_url IS NOT NULL AND hb.link_url != '' THEN 'open_url' ELSE 'none' END,
            CASE WHEN hb.link_url IS NOT NULL AND hb.link_url != '' THEN jsonb_build_object('url', hb.link_url) ELSE '{}'::jsonb END,
            hb.created_at
        FROM home_banners hb
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO banner_placements (banner_id, placement)
        SELECT hb.id, 'home'
        FROM home_banners hb
        ON CONFLICT (banner_id, placement) DO NOTHING;
    END IF;

    -- Migrate store_banners into banners + banner_placements (placement = 'store') + banner_stores
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'store_banners') THEN
        INSERT INTO banners (id, merchant_id, image_url, is_active, created_at)
        SELECT 
            sb.id,
            sb.merchant_id,
            sb.image_url,
            sb.is_active,
            sb.created_at
        FROM store_banners sb
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO banner_placements (banner_id, placement)
        SELECT sb.id, 'store'
        FROM store_banners sb
        ON CONFLICT (banner_id, placement) DO NOTHING;

        INSERT INTO banner_stores (banner_id, store_id)
        SELECT sb.id, sb.store_id
        FROM store_banners sb
        WHERE sb.store_id IS NOT NULL;
    END IF;
END $$;
