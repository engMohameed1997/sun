CREATE TABLE IF NOT EXISTS governorates (
    id SERIAL PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO governorates (name_ar, name_en) VALUES
('بغداد', 'Baghdad'),
('البصرة', 'Basra'),
('نينوى', 'Nineveh'),
('أربيل', 'Erbil'),
('بابل', 'Babil'),
('ذي قار', 'Dhi Qar'),
('السليمانية', 'Sulaymaniyah'),
('ديالى', 'Diyala'),
('الأنبار', 'Al Anbar'),
('ميسان', 'Maysan'),
('النجف', 'Najaf'),
('كربلاء', 'Karbala'),
('كركوك', 'Kirkuk'),
('صلاح الدين', 'Saladin'),
('الديوانية', 'Al Diwaniyah'),
('واسط', 'Wasit'),
('دهوك', 'Duhok'),
('المثنى', 'Al Muthanna');

CREATE TABLE IF NOT EXISTS home_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255),
    subtitle VARCHAR(255),
    image_url TEXT NOT NULL,
    link_url TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS store_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    image_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS delivery_fees (
    id SERIAL PRIMARY KEY,
    merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    governorate_id INT REFERENCES governorates(id) ON DELETE CASCADE,
    fee_iqd DECIMAL(12,2) NOT NULL,
    estimated_days INT NOT NULL,
    UNIQUE(merchant_id, governorate_id)
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(50) PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX idx_home_banners_active ON home_banners(is_active);
CREATE INDEX idx_store_banners_merchant ON store_banners(merchant_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_unread ON notifications(recipient_id) WHERE is_read = false;
