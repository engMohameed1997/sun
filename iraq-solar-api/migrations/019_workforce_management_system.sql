-- Migration 019: Workforce Dispatch System (technicians, service orders, dispatch engine, pricing)

-- ============================================================
-- 1. Technician levels (Bronze / Silver / Gold / Platinum)
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(30) UNIQUE NOT NULL,
    name_ar VARCHAR(50) NOT NULL,
    min_jobs INT NOT NULL DEFAULT 0,
    min_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
    commission_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    badge_color VARCHAR(20) NOT NULL DEFAULT '#CD7F32',
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO technician_levels (name, name_ar, min_jobs, min_rating, commission_rate, badge_color, sort_order) VALUES
    ('bronze',   'برونزي', 0,   0.00, 15.00, '#CD7F32', 1),
    ('silver',   'فضي',    20,  0.00, 12.00, '#C0C0C0', 2),
    ('gold',     'ذهبي',   100, 0.00, 10.00, '#FFD700', 3),
    ('platinum', 'بلاتيني',200, 4.80,  8.00, '#E5E4E2', 4)
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- 2. Technicians
-- ============================================================
CREATE TABLE IF NOT EXISTS technicians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(150) NOT NULL,
    profile_image_url TEXT,
    phone_private VARCHAR(20),
    phone_public VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'technician'
        CHECK (role IN ('engineer', 'installer', 'technician', 'worker')),
    specializations JSONB NOT NULL DEFAULT '[]'::jsonb,
    governorate_id INT REFERENCES governorates(id) ON DELETE SET NULL,
    district_id INT REFERENCES districts(id) ON DELETE SET NULL,
    experience_years INT NOT NULL DEFAULT 0,
    bio TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    availability_status VARCHAR(20) NOT NULL DEFAULT 'offline'
        CHECK (availability_status IN ('available', 'busy', 'suspended', 'offline', 'vacation')),
    rating NUMERIC(3,2) NOT NULL DEFAULT 0,
    completed_jobs_count INT NOT NULL DEFAULT 0,
    acceptance_rate NUMERIC(5,2) NOT NULL DEFAULT 100.00,
    avg_response_minutes INT NOT NULL DEFAULT 0,
    verification_level INT NOT NULL DEFAULT 0 CHECK (verification_level BETWEEN 0 AND 3),
    complaint_count INT NOT NULL DEFAULT 0,
    level_id UUID REFERENCES technician_levels(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technicians_role ON technicians(role);
CREATE INDEX IF NOT EXISTS idx_technicians_governorate ON technicians(governorate_id);
CREATE INDEX IF NOT EXISTS idx_technicians_availability ON technicians(availability_status);
CREATE INDEX IF NOT EXISTS idx_technicians_user ON technicians(user_id);

-- ============================================================
-- 3. Technician availability & working hours
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL UNIQUE REFERENCES technicians(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'offline'
        CHECK (status IN ('available', 'busy', 'offline', 'vacation')),
    available_from TIME,
    available_until TIME,
    working_days JSONB NOT NULL DEFAULT '["sat","sun","mon","tue","wed","thu"]'::jsonb,
    current_lat NUMERIC(10,7),
    current_lng NUMERIC(10,7),
    last_status_change_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_availability_status ON technician_availability(status);

-- ============================================================
-- 4. Technician documents
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL
        CHECK (type IN ('id_card', 'electrical_certificate', 'solar_certificate', 'license', 'personal_photo', 'work_photo')),
    url TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_documents_technician ON technician_documents(technician_id);

-- ============================================================
-- 5. Technician portfolio
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_portfolio (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    before_images JSONB NOT NULL DEFAULT '[]'::jsonb,
    after_images JSONB NOT NULL DEFAULT '[]'::jsonb,
    video_url TEXT,
    project_type VARCHAR(20) NOT NULL DEFAULT 'installation'
        CHECK (project_type IN ('installation', 'maintenance', 'inspection', 'repair')),
    system_capacity_kw NUMERIC(10,2),
    governorate VARCHAR(100),
    city VARCHAR(100),
    execution_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_portfolio_technician ON technician_portfolio(technician_id);

-- ============================================================
-- 6. Technician service zones
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_service_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    governorate_id INT NOT NULL REFERENCES governorates(id) ON DELETE CASCADE,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (technician_id, governorate_id)
);

CREATE INDEX IF NOT EXISTS idx_technician_zones_technician ON technician_service_zones(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_zones_governorate ON technician_service_zones(governorate_id);

-- ============================================================
-- 7. Technician wallet
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_wallet (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL UNIQUE REFERENCES technicians(id) ON DELETE CASCADE,
    balance_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_earned_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_commission_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    pending_payout_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    last_settlement_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_wallet_technician ON technician_wallet(technician_id);

-- ============================================================
-- 8. Technician ranking
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_ranking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL UNIQUE REFERENCES technicians(id) ON DELETE CASCADE,
    priority_score NUMERIC(5,2) NOT NULL DEFAULT 0,
    manual_order INT NOT NULL DEFAULT 0,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    is_hidden BOOLEAN NOT NULL DEFAULT false,
    last_recalculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_ranking_score ON technician_ranking(priority_score DESC);

-- ============================================================
-- 9. Service orders
-- ============================================================
CREATE TABLE IF NOT EXISTS service_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(30) UNIQUE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    order_type VARCHAR(20) NOT NULL
        CHECK (order_type IN ('installation', 'maintenance', 'inspection', 'consultation', 'repair')),
    description TEXT,
    system_size_kw NUMERIC(10,2),
    governorate_id INT REFERENCES governorates(id) ON DELETE SET NULL,
    district_id INT REFERENCES districts(id) ON DELETE SET NULL,
    address TEXT,
    lat NUMERIC(10,7),
    lng NUMERIC(10,7),
    preferred_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'new'
        CHECK (status IN ('new', 'dispatching', 'assigned', 'tech_accepted', 'on_the_way', 'arrived',
                          'working', 'waiting_customer', 'completed', 'cancelled', 'no_technician_available')),
    priority VARCHAR(10) NOT NULL DEFAULT 'normal'
        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    calculator_result JSONB,
    assigned_technician_id UUID REFERENCES technicians(id) ON DELETE SET NULL,
    dispatch_mode VARCHAR(15) NOT NULL DEFAULT 'sequential'
        CHECK (dispatch_mode IN ('sequential', 'parallel', 'hybrid')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_service_orders_customer ON service_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_service_orders_status ON service_orders(status);
CREATE INDEX IF NOT EXISTS idx_service_orders_type ON service_orders(order_type);
CREATE INDEX IF NOT EXISTS idx_service_orders_technician ON service_orders(assigned_technician_id);

-- ============================================================
-- 10. Dispatch settings (per service type)
-- ============================================================
CREATE TABLE IF NOT EXISTS dispatch_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_type VARCHAR(20) UNIQUE NOT NULL
        CHECK (service_type IN ('installation', 'maintenance', 'inspection', 'consultation', 'repair')),
    dispatch_mode VARCHAR(15) NOT NULL DEFAULT 'hybrid'
        CHECK (dispatch_mode IN ('sequential', 'parallel', 'hybrid')),
    response_timeout_minutes INT NOT NULL DEFAULT 10,
    parallel_candidates_count INT NOT NULL DEFAULT 3,
    minimum_score NUMERIC(5,2) NOT NULL DEFAULT 0,
    auto_assign_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO dispatch_settings (service_type, dispatch_mode, response_timeout_minutes, parallel_candidates_count, minimum_score) VALUES
    ('installation',  'hybrid',   10, 3, 60.00),
    ('maintenance',   'parallel',  3, 5, 50.00),
    ('inspection',    'parallel',  5, 3, 40.00),
    ('consultation',  'parallel',  5, 3, 40.00),
    ('repair',        'hybrid',    5, 3, 50.00)
ON CONFLICT (service_type) DO NOTHING;

-- ============================================================
-- 11. Dispatch queue
-- ============================================================
CREATE TABLE IF NOT EXISTS dispatch_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    priority_score NUMERIC(5,2) NOT NULL DEFAULT 0,
    dispatch_mode VARCHAR(15) NOT NULL DEFAULT 'sequential'
        CHECK (dispatch_mode IN ('sequential', 'parallel', 'hybrid')),
    position INT NOT NULL DEFAULT 1,
    status VARCHAR(15) NOT NULL DEFAULT 'queued'
        CHECK (status IN ('queued', 'sent', 'accepted', 'rejected', 'expired', 'cancelled')),
    selection_reason JSONB NOT NULL DEFAULT '{}'::jsonb,
    sent_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (service_order_id, technician_id)
);

CREATE INDEX IF NOT EXISTS idx_dispatch_queue_order ON dispatch_queue(service_order_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_queue_technician ON dispatch_queue(technician_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_queue_status ON dispatch_queue(status);

-- ============================================================
-- 12. Technician dispatch stats (Fair Dispatch)
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_dispatch_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL UNIQUE REFERENCES technicians(id) ON DELETE CASCADE,
    orders_received_this_month INT NOT NULL DEFAULT 0,
    orders_received_this_week INT NOT NULL DEFAULT 0,
    total_orders_received INT NOT NULL DEFAULT 0,
    total_earnings_this_month NUMERIC(14,2) NOT NULL DEFAULT 0,
    last_order_received_at TIMESTAMPTZ,
    last_order_completed_at TIMESTAMPTZ,
    days_since_last_order INT NOT NULL DEFAULT 0,
    is_new_technician BOOLEAN NOT NULL DEFAULT true,
    new_technician_orders_count INT NOT NULL DEFAULT 0,
    fairness_boost NUMERIC(5,2) NOT NULL DEFAULT 0,
    last_boost_calculated_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dispatch_stats_technician ON technician_dispatch_stats(technician_id);

-- ============================================================
-- 13. Technician GPS tracking
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    lat NUMERIC(10,7) NOT NULL,
    lng NUMERIC(10,7) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'on_the_way'
        CHECK (status IN ('on_the_way', 'arrived', 'working', 'idle')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_tracking_order ON technician_tracking(order_id, created_at DESC);

-- ============================================================
-- 14. Technician leads
-- ============================================================
CREATE TABLE IF NOT EXISTS technician_leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    customer_name VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    order_type VARCHAR(20) NOT NULL
        CHECK (order_type IN ('installation', 'maintenance', 'inspection', 'consultation', 'repair')),
    description TEXT,
    system_size_kw NUMERIC(10,2),
    governorate_id INT REFERENCES governorates(id) ON DELETE SET NULL,
    district_id INT REFERENCES districts(id) ON DELETE SET NULL,
    address TEXT,
    estimated_price_iqd NUMERIC(14,2),
    status VARCHAR(20) NOT NULL DEFAULT 'pending_review'
        CHECK (status IN ('pending_review', 'approved', 'rejected', 'converted')),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    converted_order_id UUID REFERENCES service_orders(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technician_leads_technician ON technician_leads(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_leads_status ON technician_leads(status);

-- ============================================================
-- 15. Order assignments (final dispatch result)
-- ============================================================
CREATE TABLE IF NOT EXISTS order_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    assigned_by VARCHAR(20) NOT NULL DEFAULT 'dispatch_engine'
        CHECK (assigned_by IN ('dispatch_engine', 'admin')),
    assigned_by_admin UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'rejected', 'completed', 'expired')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT,
    completion_time TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_order_assignments_order ON order_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_assignments_technician ON order_assignments(technician_id);

-- ============================================================
-- 16. Service order status history
-- ============================================================
CREATE TABLE IF NOT EXISTS service_order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_order_history_order ON service_order_status_history(order_id, created_at);

-- ============================================================
-- 17. Job tasks (checklist)
-- ============================================================
CREATE TABLE IF NOT EXISTS job_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_job_tasks_order ON job_tasks(order_id, sort_order);

-- ============================================================
-- 18. Job media
-- ============================================================
CREATE TABLE IF NOT EXISTS job_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES technicians(id) ON DELETE SET NULL,
    type VARCHAR(15) NOT NULL
        CHECK (type IN ('photo', 'video', 'note', 'signature', 'gps_proof')),
    url TEXT,
    content TEXT,
    lat NUMERIC(10,7),
    lng NUMERIC(10,7),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_media_order ON job_media(order_id);

-- ============================================================
-- 19. Customer reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS customer_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL UNIQUE REFERENCES service_orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    quality_rating INT NOT NULL CHECK (quality_rating BETWEEN 1 AND 5),
    punctuality_rating INT NOT NULL CHECK (punctuality_rating BETWEEN 1 AND 5),
    speed_rating INT NOT NULL CHECK (speed_rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customer_reviews_technician ON customer_reviews(technician_id);

-- ============================================================
-- 20. Service pricing (per order)
-- ============================================================
CREATE TABLE IF NOT EXISTS service_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL UNIQUE REFERENCES service_orders(id) ON DELETE CASCADE,
    base_price_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    platform_commission_percent NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    platform_commission_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    technician_payout_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(25) NOT NULL DEFAULT 'unpaid'
        CHECK (payment_status IN ('unpaid', 'pending', 'paid_to_technician', 'settled')),
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_pricing_status ON service_pricing(payment_status);

-- ============================================================
-- 21. Service price tiers (reference pricing per service type)
-- ============================================================
CREATE TABLE IF NOT EXISTS service_price_tiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_type VARCHAR(20) UNIQUE NOT NULL
        CHECK (service_type IN ('installation', 'maintenance', 'inspection', 'consultation', 'repair')),
    min_price_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    max_price_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    default_price_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    price_per_kw_iqd NUMERIC(14,2) NOT NULL DEFAULT 0,
    commission_percent NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO service_price_tiers (service_type, min_price_iqd, max_price_iqd, default_price_iqd, price_per_kw_iqd, commission_percent) VALUES
    ('installation', 150000, 5000000, 250000, 120000, 15.00),
    ('maintenance',   50000,  500000,  75000,      0, 15.00),
    ('inspection',    25000,  150000,  50000,      0, 15.00),
    ('consultation',  25000,  200000,  50000,      0, 15.00),
    ('repair',        50000, 1000000, 100000,      0, 15.00)
ON CONFLICT (service_type) DO NOTHING;
