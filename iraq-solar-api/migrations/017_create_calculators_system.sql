-- Migration 017: Create Calculators System with normalized roles and display settings

CREATE TABLE IF NOT EXISTS calculators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_key VARCHAR(50) UNIQUE NOT NULL,
    title_ar VARCHAR(100) NOT NULL,
    title_en VARCHAR(100),
    subtitle_ar VARCHAR(150),
    subtitle_en VARCHAR(150),
    icon_key VARCHAR(50) NOT NULL,
    background_image_url VARCHAR(500),
    badge VARCHAR(50),
    color_hex VARCHAR(20) DEFAULT '#F9A826',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS calculator_roles (
    calculator_id UUID REFERENCES calculators(id) ON DELETE CASCADE,
    role VARCHAR(30) NOT NULL,
    PRIMARY KEY (calculator_id, role)
);

CREATE INDEX IF NOT EXISTS idx_calc_roles_role ON calculator_roles(role);
CREATE INDEX IF NOT EXISTS idx_calculators_active_featured ON calculators(is_active, is_featured, sort_order);

-- Seed Initial 12 Solar Calculators
DO $$
DECLARE
    cid_sizing UUID := uuid_generate_v4();
    cid_roi UUID := uuid_generate_v4();
    cid_battery_runtime UUID := uuid_generate_v4();
    cid_appliance UUID := uuid_generate_v4();
    cid_panels UUID := uuid_generate_v4();
    cid_roof UUID := uuid_generate_v4();
    cid_full_cost UUID := uuid_generate_v4();
    cid_cable_sizing UUID := uuid_generate_v4();
    cid_mppt_string UUID := uuid_generate_v4();
    cid_breakers_fuses UUID := uuid_generate_v4();
    cid_battery_bank UUID := uuid_generate_v4();
    cid_solar_production UUID := uuid_generate_v4();
BEGIN

    -- 1. System Sizing
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_sizing, 'system_sizing', 'حجم المنظومة', 'System Sizing', 'الألواح، الانفرتر، والبطاريات', 'Panels, Inverter & Batteries', 'sun', 'ضرورية', '#FF9800', true, 1)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_sizing, 'customer'), (cid_sizing, 'installer'), (cid_sizing, 'engineer'), (cid_sizing, 'merchant'), (cid_sizing, 'admin')
    ON CONFLICT DO NOTHING;

    -- 2. ROI & Savings
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_roi, 'roi', 'التوفير و ROI', 'ROI & Savings', 'فترة استرجاع المال والتوفير', 'Payback Period & Savings', 'savings', 'استرداد', '#4CAF50', true, 2)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_roi, 'customer'), (cid_roi, 'installer'), (cid_roi, 'engineer'), (cid_roi, 'merchant'), (cid_roi, 'admin')
    ON CONFLICT DO NOTHING;

    -- 3. Battery Runtime
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_battery_runtime, 'battery_runtime', 'تشغيل البطاريات', 'Battery Runtime', 'ساعات التغذية المستمرة', 'Backup Hours', 'battery', 'ساعات', '#2196F3', false, 3)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_battery_runtime, 'customer'), (cid_battery_runtime, 'installer'), (cid_battery_runtime, 'engineer'), (cid_battery_runtime, 'merchant'), (cid_battery_runtime, 'admin')
    ON CONFLICT DO NOTHING;

    -- 4. Appliance Consumption
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_appliance, 'appliance', 'استهلاك الأجهزة', 'Appliance Load', 'استهلاك المكيف والثلاجة', 'AC & Fridge Load', 'power', 'أجهزة', '#9C27B0', false, 4)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_appliance, 'customer'), (cid_appliance, 'installer'), (cid_appliance, 'engineer'), (cid_appliance, 'merchant'), (cid_appliance, 'admin')
    ON CONFLICT DO NOTHING;

    -- 5. Panels Needed
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_panels, 'panels', 'الألواح بالاستهلاك', 'Panels by Bill', 'إدخال استهلاك الشهري kWh', 'Monthly kWh Bill', 'grid', 'عدد ألواح', '#FF5722', false, 5)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_panels, 'customer'), (cid_panels, 'installer'), (cid_panels, 'engineer'), (cid_panels, 'merchant'), (cid_panels, 'admin')
    ON CONFLICT DO NOTHING;

    -- 6. Roof Capacity
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_roof, 'roof', 'مساحة السطح', 'Roof Capacity', 'أقصى عدد ألواح يستوعبه السطح', 'Max Surface Panels', 'roof', 'مساحة السطح', '#009688', false, 6)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_roof, 'customer'), (cid_roof, 'installer'), (cid_roof, 'engineer'), (cid_roof, 'merchant'), (cid_roof, 'admin')
    ON CONFLICT DO NOTHING;

    -- 7. Full Kit Cost
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_full_cost, 'full_cost', 'الكلفة ومتجر الشراء', 'Full Kit Cost', 'حساب التكلفة وعرض المتاجر', 'Cost & Store Link', 'shopping_bag', 'ربط المتجر', '#FF5252', true, 7)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_full_cost, 'customer'), (cid_full_cost, 'installer'), (cid_full_cost, 'engineer'), (cid_full_cost, 'merchant'), (cid_full_cost, 'admin')
    ON CONFLICT DO NOTHING;

    -- 8. Cable Sizing
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_cable_sizing, 'cable_sizing', 'Cable & VDrop', 'Cable & VDrop', 'سمك السلك وهبوط الجهد', 'Cable Gauge & Voltage Drop', 'cable', 'كابلات', '#3F51B5', true, 8)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_cable_sizing, 'installer'), (cid_cable_sizing, 'engineer'), (cid_cable_sizing, 'merchant'), (cid_cable_sizing, 'admin')
    ON CONFLICT DO NOTHING;

    -- 9. MPPT String
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_mppt_string, 'mppt_string', 'MPPT String', 'MPPT String', 'سلاسل الألواح وتأثير الحرارة', 'PV Strings & Temp Coeff', 'tune', 'MPPT', '#673AB7', true, 9)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_mppt_string, 'engineer'), (cid_mppt_string, 'admin')
    ON CONFLICT DO NOTHING;

    -- 10. Breakers & Fuses
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_breakers_fuses, 'breakers_fuses', 'Breaker & Fuse', 'Breaker & Fuse', 'قواطع DC/AC والفيوزات', 'DC/AC Breakers & Fuses', 'shield', 'حماية', '#FF6F00', false, 10)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_breakers_fuses, 'installer'), (cid_breakers_fuses, 'engineer'), (cid_breakers_fuses, 'merchant'), (cid_breakers_fuses, 'admin')
    ON CONFLICT DO NOTHING;

    -- 11. Battery Bank
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_battery_bank, 'battery_bank', 'بنك البطاريات', 'Battery Bank', 'توصيل توالي/توازي Series/Parallel', 'Series/Parallel Wiring', 'battery_saver', 'توصيلات', '#00838F', false, 11)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_battery_bank, 'installer'), (cid_battery_bank, 'engineer'), (cid_battery_bank, 'merchant'), (cid_battery_bank, 'admin')
    ON CONFLICT DO NOTHING;

    -- 12. Solar Production
    INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, badge, color_hex, is_featured, sort_order)
    VALUES (cid_solar_production, 'solar_production', 'إنتاجية المحافظات', 'Solar Production', 'إنتاج العراق والزاوية المثالية', 'Province Radiation & Tilt Angle', 'map', 'محافظات', '#795548', false, 12)
    ON CONFLICT (route_key) DO NOTHING;
    INSERT INTO calculator_roles (calculator_id, role) VALUES 
        (cid_solar_production, 'installer'), (cid_solar_production, 'engineer'), (cid_solar_production, 'merchant'), (cid_solar_production, 'admin')
    ON CONFLICT DO NOTHING;

END $$;
