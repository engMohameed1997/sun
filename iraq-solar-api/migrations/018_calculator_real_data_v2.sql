-- Migration 018: Create tables for Calculator Real Data, Solar Irradiance, Energy Costs, Market Price Index, and Appliance Presets

-- 1. Governorate Solar Data (Climate / Irradiance - fixed)
CREATE TABLE IF NOT EXISTS governorate_solar_data (
    governorate_id INT PRIMARY KEY REFERENCES governorates(id) ON DELETE CASCADE,
    peak_sun_hours NUMERIC(4,2) NOT NULL DEFAULT 5.50,
    optimal_tilt_angle NUMERIC(4,2) NOT NULL DEFAULT 32.00,
    min_winter_temp_c NUMERIC(4,1) NOT NULL DEFAULT 0.0,
    max_summer_temp_c NUMERIC(4,1) NOT NULL DEFAULT 50.0,
    dataset_version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Governorate Energy Cost (Economic Tariffs - fluctuates)
CREATE TABLE IF NOT EXISTS governorate_energy_cost (
    governorate_id INT PRIMARY KEY REFERENCES governorates(id) ON DELETE CASCADE,
    generator_ampere_price_iqd NUMERIC(10,2) NOT NULL DEFAULT 15000.00,
    grid_tariff_per_kwh_iqd NUMERIC(10,2) NOT NULL DEFAULT 35.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Appliance Presets (Home appliances electrical specs)
CREATE TABLE IF NOT EXISTS appliance_presets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    default_wattage NUMERIC(8,2) NOT NULL,
    power_factor NUMERIC(3,2) NOT NULL DEFAULT 0.90,
    surge_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.00,
    voltage NUMERIC(5,1) NOT NULL DEFAULT 220.0,
    phase INT NOT NULL DEFAULT 1,
    frequency NUMERIC(4,1) NOT NULL DEFAULT 50.0,
    default_daily_hours NUMERIC(4,2) NOT NULL DEFAULT 4.0,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    icon_key VARCHAR(50) DEFAULT 'power',
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Market Price Index Snapshot (Fast pre-calculated pricing benchmarks)
CREATE TABLE IF NOT EXISTS market_price_index (
    id INT PRIMARY KEY DEFAULT 1,
    panel_price_per_watt_iqd NUMERIC(10,2) NOT NULL DEFAULT 300.00,
    min_panel_price_per_watt_iqd NUMERIC(10,2) NOT NULL DEFAULT 250.00,
    max_panel_price_per_watt_iqd NUMERIC(10,2) NOT NULL DEFAULT 380.00,
    inverter_price_per_kw_iqd NUMERIC(10,2) NOT NULL DEFAULT 150000.00,
    battery_price_per_kwh_iqd NUMERIC(10,2) NOT NULL DEFAULT 350000.00,
    usd_to_iqd_rate NUMERIC(10,2) NOT NULL DEFAULT 1500.00,
    installation_cost_per_kw_iqd NUMERIC(10,2) NOT NULL DEFAULT 120000.00,
    installation_base_fee_iqd NUMERIC(10,2) NOT NULL DEFAULT 225000.00,
    pricing_version INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial market price index record if empty
INSERT INTO market_price_index (id, panel_price_per_watt_iqd, min_panel_price_per_watt_iqd, max_panel_price_per_watt_iqd, inverter_price_per_kw_iqd, battery_price_per_kwh_iqd, usd_to_iqd_rate, installation_cost_per_kw_iqd, installation_base_fee_iqd, pricing_version)
VALUES (1, 300.00, 250.00, 380.00, 150000.00, 350000.00, 1500.00, 120000.00, 225000.00, 1)
ON CONFLICT (id) DO NOTHING;

-- Seed Solar Data for 18 Iraqi Governorates
DO $$
DECLARE
    gov_record RECORD;
BEGIN
    FOR gov_record IN SELECT id, name_ar FROM governorates LOOP
        INSERT INTO governorate_solar_data (governorate_id, peak_sun_hours, optimal_tilt_angle, min_winter_temp_c, max_summer_temp_c, dataset_version)
        VALUES (
            gov_record.id,
            CASE 
                WHEN gov_record.name_ar IN ('البصرة', 'ذي قار', 'ميسان', 'المثنى') THEN 5.80
                WHEN gov_record.name_ar IN ('بغداد', 'النجف', 'كربلاء', 'واسط', 'بابل', 'القادسية') THEN 5.50
                WHEN gov_record.name_ar IN ('أربيل', 'دهوك', 'السليمانية', 'نينوى') THEN 5.20
                ELSE 5.40
            END,
            CASE 
                WHEN gov_record.name_ar IN ('البصرة', 'ذي قار') THEN 30.00
                WHEN gov_record.name_ar IN ('أربيل', 'دهوك', 'السليمانية') THEN 36.00
                ELSE 33.00
            END,
            CASE 
                WHEN gov_record.name_ar IN ('أربيل', 'دهوك', 'السليمانية') THEN -5.0
                ELSE 2.0
            END,
            CASE 
                WHEN gov_record.name_ar IN ('البصرة', 'ميسان') THEN 52.0
                ELSE 48.0
            END,
            1
        ) ON CONFLICT (governorate_id) DO NOTHING;

        INSERT INTO governorate_energy_cost (governorate_id, generator_ampere_price_iqd, grid_tariff_per_kwh_iqd)
        VALUES (
            gov_record.id,
            18000.00,
            35.00
        ) ON CONFLICT (governorate_id) DO NOTHING;
    END LOOP;
END $$;

-- Seed Standard Iraqi Home Appliances
INSERT INTO appliance_presets (name_ar, name_en, default_wattage, power_factor, surge_multiplier, voltage, phase, frequency, default_daily_hours, category, icon_key, sort_order)
VALUES 
('سبليت 1.5 طن (إنفرتر)', 'Split AC 1.5 Ton (Inverter)', 1400.00, 0.92, 2.00, 220.0, 1, 50.0, 8.0, 'cooling', 'ac_unit', 1),
('سبليت 2 طن (عادي)', 'Split AC 2 Ton (Standard)', 2400.00, 0.85, 3.50, 220.0, 1, 50.0, 8.0, 'cooling', 'ac_unit', 2),
('مكيف جداري 1.5 طن', 'Window AC 1.5 Ton', 1800.00, 0.85, 3.00, 220.0, 1, 50.0, 6.0, 'cooling', 'ac_unit', 3),
('ثلاجة قدم 16 (إنفرتر)', 'Refrigerator 16 cu ft', 180.00, 0.90, 2.50, 220.0, 1, 50.0, 24.0, 'kitchen', 'kitchen', 4),
('مجمدة منزلية', 'Chest Freezer', 220.00, 0.88, 3.00, 220.0, 1, 50.0, 24.0, 'kitchen', 'kitchen', 5),
('مضخة ماء (1 حصان)', 'Water Pump 1 HP', 750.00, 0.80, 3.00, 220.0, 1, 50.0, 2.0, 'pumps', 'water_drop', 6),
('غسالة ملابس أوتوماتيك', 'Washing Machine Auto', 500.00, 0.90, 1.50, 220.0, 1, 50.0, 1.5, 'laundry', 'local_laundry_service', 7),
('شاشة تلفزيون 55 بوصة', 'TV 55 inch LED', 120.00, 0.95, 1.00, 220.0, 1, 50.0, 6.0, 'electronics', 'tv', 8),
('إضاءة منزلية LED (إجمالي)', 'Home LED Lighting', 150.00, 0.95, 1.00, 220.0, 1, 50.0, 8.0, 'lighting', 'lightbulb', 9),
('كيزر ماء كهربائي 50 لتر', 'Electric Water Heater', 1800.00, 1.00, 1.00, 220.0, 1, 50.0, 3.0, 'heating', 'water_heater', 10),
('مروحة سقف', 'Ceiling Fan', 75.00, 0.85, 1.20, 220.0, 1, 50.0, 12.0, 'cooling', 'mode_fan', 11),
('راوتر ومقوي شبكة', 'WiFi Router & AP', 25.00, 0.95, 1.00, 220.0, 1, 50.0, 24.0, 'electronics', 'router', 12)
ON CONFLICT DO NOTHING;
