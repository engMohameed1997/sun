package database

import (
	"log"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

func SeedDatabase(db *sqlx.DB) error {
	if db == nil {
		return nil
	}

	// 0. Ensure uuid-ossp extension and enterprise banner tables exist
	_, _ = db.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`)
	_, _ = db.Exec(`ALTER TABLE products ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';`)
	_, _ = db.Exec(`
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

		CREATE TABLE IF NOT EXISTS banner_placements (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
			placement VARCHAR(50) NOT NULL,
			created_at TIMESTAMPTZ DEFAULT NOW(),
			UNIQUE(banner_id, placement)
		);

		CREATE TABLE IF NOT EXISTS banner_stores (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
			store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
			branch_id UUID REFERENCES store_branches(id) ON DELETE CASCADE,
			created_at TIMESTAMPTZ DEFAULT NOW()
		);

		CREATE TABLE IF NOT EXISTS banner_events (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			banner_id UUID NOT NULL REFERENCES banners(id) ON DELETE CASCADE,
			event_type VARCHAR(20) NOT NULL,
			user_id UUID REFERENCES users(id) ON DELETE SET NULL,
			device_id VARCHAR(255),
			metadata JSONB DEFAULT '{}',
			created_at TIMESTAMPTZ DEFAULT NOW()
		);

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
	`)

	// 0. Ensure v_orders_full view exists
	_, _ = db.Exec(`
		CREATE OR REPLACE VIEW v_orders_full AS
		WITH order_derived_store AS (
			SELECT DISTINCT ON (oi.order_id)
				oi.order_id,
				COALESCE(oi.store_id, p.store_id) AS store_id,
				COALESCE(oi.branch_id, p.branch_id) AS branch_id
			FROM order_items oi
			LEFT JOIN products p ON oi.product_id = p.id
			ORDER BY oi.order_id, oi.id
		)
		SELECT
			o.id,
			o.user_id,
			COALESCE(o.store_id, ods.store_id)   AS store_id,
			COALESCE(o.branch_id, ods.branch_id) AS branch_id,
			o.status,
			o.total_amount_iqd,
			o.shipping_address,
			o.payment_method,
			o.payment_status,
			o.created_at,
			o.updated_at,
			u.full_name   AS customer_name,
			u.phone       AS customer_phone,
			u.governorate AS customer_governorate,
			u.city        AS customer_city,
			s.name        AS store_name,
			s.slug        AS store_slug,
			s.logo_url    AS store_logo_url,
			s.phone       AS store_phone,
			b.name        AS branch_name,
			b.address     AS branch_address,
			b.city        AS branch_city,
			b.phone       AS branch_phone,
			g.name_ar     AS branch_governorate_ar,
			g.name_en     AS branch_governorate_en
		FROM orders o
		LEFT JOIN order_derived_store ods ON o.id = ods.order_id
		LEFT JOIN users          u ON o.user_id                            = u.id
		LEFT JOIN stores         s ON COALESCE(o.store_id, ods.store_id)   = s.id
		LEFT JOIN store_branches b ON COALESCE(o.branch_id, ods.branch_id) = b.id
		LEFT JOIN governorates   g ON b.governorate_id                     = g.id;
	`)

	// 1. Seed Categories if empty
	var catCount int
	err := db.Get(&catCount, "SELECT COUNT(*) FROM categories")
	if err == nil && catCount == 0 {
		log.Println("Seeding default solar categories into DB...")
		categories := []struct {
			Name        string
			Description string
		}{
			{"ألواح شمسية", "ألواح طاقة شمسية N-Type / TOPCon عالية الكفاءة"},
			{"عواكس طاقة (انفيرترات)", "انفيرترات هجينة وإضافية سين ويف"},
			{"بطاريات خزن ليثيوم", "بطاريات LiFePO4 دورات شحن 6000+"},
			{"هياكل وقواعد تثبيت", "هياكل تثبيت ألمنيوم ومجلفنة مقاومة للرياح"},
			{"كوابل ومحولات", "كوابل DC شمسية ومحولات ومستلزمات الحماية والفيوزات"},
		}

		for _, cat := range categories {
			_, _ = db.Exec("INSERT INTO categories (name, description) VALUES ($1, $2) ON CONFLICT DO NOTHING", cat.Name, cat.Description)
		}
	}

	// 2. Seed Governorates if empty
	var govCount int
	err = db.Get(&govCount, "SELECT COUNT(*) FROM governorates")
	if err == nil && govCount == 0 {
		log.Println("Seeding Iraqi Governorates into DB...")
		govs := []struct {
			ID     int
			NameAr string
			NameEn string
		}{
			{1, "بغداد", "Baghdad"},
			{2, "البصرة", "Basra"},
			{3, "نينوى (الموصل)", "Nineveh"},
			{4, "أربيل", "Erbil"},
			{5, "بابل (الحلة)", "Babil"},
			{6, "ذي قار (الناصرية)", "Dhi Qar"},
			{7, "السليمانية", "Sulaymaniyah"},
			{8, "ديالى (بعقوبة)", "Diyala"},
			{9, "الأنبار (الرمادي)", "Al Anbar"},
			{10, "ميسان (العمارة)", "Maysan"},
			{11, "النجف الأشرف", "Najaf"},
			{12, "كربلاء المقدسة", "Karbala"},
			{13, "كركوك", "Kirkuk"},
			{14, "صلاح الدين (تكريت)", "Saladin"},
			{15, "الديوانية (القادسية)", "Al Diwaniyah"},
			{16, "واسط (الكوت)", "Wasit"},
			{17, "دهوك", "Duhok"},
			{18, "المثنى (السماوة)", "Al Muthanna"},
		}
		for _, g := range govs {
			_, _ = db.Exec("INSERT INTO governorates (id, name_ar, name_en) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name_ar = EXCLUDED.name_ar, name_en = EXCLUDED.name_en", g.ID, g.NameAr, g.NameEn)
		}
	}

	// 3. Seed Districts if empty
	var distCount int
	err = db.Get(&distCount, "SELECT COUNT(*) FROM districts")
	if err == nil && distCount == 0 {
		log.Println("Seeding Comprehensive Iraqi Districts into DB...")
		districtsData := []struct {
			GovID  int
			NameAr string
			NameEn string
		}{
			// 1. Baghdad
			{1, "الكرادة / الجادرية", "Karrada / Jadriya"},
			{1, "المنصور / اليرموك", "Mansour / Yarmouk"},
			{1, "الأعظمية / الصليخ", "Adhamiya / Slaikh"},
			{1, "شارع فلسطين / زيونة", "Palestine Street / Zayouna"},
			{1, "الكاظمية المقدسة", "Kadhimiya"},
			{1, "الدورة / السيدية", "Dora / Saydiya"},
			{1, "العامرية / الغزالية", "Amiriya / Ghazaliya"},
			{1, "بغداد الجديدة / الغدير", "New Baghdad / Ghadir"},
			{1, "الشعب / البنوك", "Shaab / Banook"},
			{1, "مدينة الصدر / الشعلة", "Sadr City / Shula"},
			{1, "أبو غريب", "Abu Ghraib"},
			{1, "التاجي", "Taji"},
			{1, "المحمودية", "Mahmudiya"},
			{1, "المدائن / سلمان باك", "Al-Madain / Salman Pak"},
			{1, "الطارمية", "Tarmiyah"},

			// 2. Basra
			{2, "مركز البصرة / العشار", "Basra Center / Ashar"},
			{2, "المعقل / الجبيلة", "Maqil / Jubaila"},
			{2, "الزبير", "Al-Zubair"},
			{2, "الهارثة", "Al-Hartha"},
			{2, "القرنة", "Al-Qurna"},
			{2, "شط العرب / تنومة", "Shatt Al-Arab / Tanuma"},
			{2, "أبو الخصيب", "Abu Al-Khaseeb"},
			{2, "الفاو", "Al-Faw"},
			{2, "المدينة", "Al-Mudaina"},
			{2, "الصادق", "Al-Sadiq"},

			// 3. Nineveh
			{3, "الموصل - الساحل الأيسر (الزهور / الزراعي)", "Mosul Left Bank"},
			{3, "الموصل - الساحل الأيمن (الدواسة / الدواجن)", "Mosul Right Bank"},
			{3, "تلعفر", "Tel Afar"},
			{3, "الحمدانية / برطلة", "Hamdaniya / Bartella"},
			{3, "سنجار", "Sinjar"},
			{3, "الشيخان", "Shekhan"},
			{3, "تلكيف", "Tel Keppe"},
			{3, "الحضر", "Hatra"},
			{3, "البعاج", "Al-Ba’aj"},
			{3, "مخمور", "Makhmour"},
			{3, "عقرة", "Akre"},

			// 4. Erbil
			{4, "مركز أربيل / شورتة", "Erbil Center"},
			{4, "عينكاوة", "Ankawa"},
			{4, "شارع 100م / 60م", "100m Street"},
			{4, "سوران", "Soran"},
			{4, "شقلاوة", "Shaqlawa"},
			{4, "كوية / كويسنجق", "Koya"},
			{4, "خبات", "Khabat"},
			{4, "ميركة سور", "Mergasor"},
			{4, "چومان", "Choman"},
			{4, "رواندوز", "Rawanduz"},

			// 5. Babil
			{5, "الحلة - المركز (شارع 40 / نادر)", "Hilla Center"},
			{5, "المحاويل", "Al-Mahawil"},
			{5, "المسيب / جرف الصخر", "Al-Musayab"},
			{5, "القاسم", "Al-Qasim"},
			{5, "الهاشمية", "Al-Hashimiya"},
			{5, "الحمزة الغربي", "Al-Hamza Al-Gharbi"},
			{5, "الكفل", "Al-Kifl"},

			// 6. Dhi Qar
			{6, "الناصرية - المركز (الحبوبي / الشوملي)", "Nasiriyah Center"},
			{6, "الشطرة", "Al-Shatrah"},
			{6, "الرفاعي", "Al-Rifai"},
			{6, "سوق الشيوخ", "Suq Al-Shuyukh"},
			{6, "الجبايش / الأهوار", "Al-Chibayish"},
			{6, "الغراف", "Al-Gharraf"},
			{6, "قلعة سكر", "Qalat Sukkar"},
			{6, "الدواية", "Al-Dawayah"},

			// 7. Sulaymaniyah
			{7, "السليمانية - المركز (عقاري / مجيد آوا)", "Sulaymaniyah Center"},
			{7, "جمجمال", "Chamchamal"},
			{7, "كلار", "Kalar"},
			{7, "رانية", "Ranya"},
			{7, "دوكان", "Dokan"},
			{7, "بنجوين", "Penjwen"},
			{7, "دربندخان", "Darbandikhan"},
			{7, "قلعة دزة / پشدر", "Qaladiza"},
			{7, "سيد صادق", "Said Sadiq"},

			// 8. Diyala
			{8, "بعقوبة - المركز (التحرير / العصري)", "Baqubah Center"},
			{8, "المقدادية", "Muqdadiya"},
			{8, "خانقين", "Khanaqin"},
			{8, "الخالص", "Al-Khalis"},
			{8, "بلدروز", "Balad Ruz"},
			{8, "كفري", "Kifri"},
			{8, "مندلي", "Mandali"},

			// 9. Al Anbar
			{9, "الرمادي - المركز (شارع 17 / التأميم)", "Ramadi Center"},
			{9, "الفلوجة - المركز (الجمهورية / الجولان)", "Fallujah Center"},
			{9, "هيت", "Heet"},
			{9, "القائم", "Al-Qaim"},
			{9, "حديثة", "Haditha"},
			{9, "الرطبة", "Al-Rutba"},
			{9, "عنة", "Ana"},
			{9, "راوة", "Rawa"},
			{9, "الكرمة", "Karma"},

			// 10. Maysan
			{10, "العمارة - المركز (القطاع / العرضات)", "Amarah Center"},
			{10, "المجر الكبير", "Al-Majar Al-Kabeer"},
			{10, "علي الغربي", "Ali Al-Gharbi"},
			{10, "قلعة صالح", "Qalat Saleh"},
			{10, "الميمونة", "Al-Maymouna"},
			{10, "الكحلاء", "Al-Kahlaa"},

			// 11. Najaf
			{11, "النجف - المركز (الروان / الغدير)", "Najaf Center"},
			{11, "الكوفة المقدسة", "Kufa"},
			{11, "المناذرة", "Al-Manathera"},
			{11, "المشخاب", "Al-Meshkhab"},
			{11, "الحيدرية", "Al-Haidariya"},

			// 12. Karbala
			{12, "كربلاء - المركز (البلدية / الحسين)", "Karbala Center"},
			{12, "الهندية / طويريج", "Al-Hindiya"},
			{12, "عين التمر", "Ain Al-Tamur"},
			{12, "الحر", "Al-Hurr"},
			{12, "الجدول الغربي", "Al-Jadwal Al-Gharbi"},

			// 13. Kirkuk
			{13, "كركوك - المركز (طريق بغداد / رحيماوا)", "Kirkuk Center"},
			{13, "الحويجة", "Al-Hawija"},
			{13, "داقوق", "Daqoq"},
			{13, "دبس", "Dibs"},

			// 14. Saladin
			{14, "تكريت - المركز (القادسية / الزهور)", "Tikrit Center"},
			{14, "سامراء المقدسة", "Samarra"},
			{14, "بلد", "Balad"},
			{14, "الدجيل", "Dujail"},
			{14, "طوزخورماتو", "Tuz Khurmatu"},
			{14, "بيجي", "Baiji"},
			{14, "الشرقاط", "Al-Shirqat"},
			{14, "الدور", "Al-Dour"},

			// 15. Al Diwaniyah
			{15, "الديوانية - المركز (الجديدة / الجزائر)", "Diwaniyah Center"},
			{15, "عفك", "Afaq"},
			{15, "الشامية", "Al-Shamiya"},
			{15, "الحمزة الشرقي", "Al-Hamza Al-Sharqi"},
			{15, "غماس", "Ghammas"},

			// 16. Wasit
			{16, "الكوت - المركز (الهورة / الزهراء)", "Kut Center"},
			{16, "الحي", "Al-Hayy"},
			{16, "النعمانية", "Al-Numaniya"},
			{16, "الصويرة", "Al-Suwaira"},
			{16, "العزيزية", "Al-Aziziyah"},
			{16, "بدرة", "Badra"},

			// 17. Duhok
			{17, "دهوك - المركز (ماسيك / مالطا)", "Duhok Center"},
			{17, "زاخو", "Zakho"},
			{17, "ئامێدی / العمادية", "Amadiya"},
			{17, "سميل", "Sumeil"},
			{17, "عقرة", "Akre"},
			{17, "شيخان", "Shekhan"},
			{17, "بردرش", "Bardarash"},

			// 18. Al Muthanna
			{18, "السماوة - المركز (الشرقي / العسكري)", "Samawah Center"},
			{18, "الرميثة", "Al-Rumaitha"},
			{18, "الخضر", "Al-Khidir"},
			{18, "السلمان", "Al-Salman"},
			{18, "الوركاء", "Al-Warka"},
		}
		for _, d := range districtsData {
			_, _ = db.Exec("INSERT INTO districts (governorate_id, name_ar, name_en) VALUES ($1, $2, $3)", d.GovID, d.NameAr, d.NameEn)
		}
	}

	// 4. Seed Admin User ONLY if no admin exists
	var adminCount int
	err = db.Get(&adminCount, "SELECT COUNT(*) FROM users WHERE role = 'admin'")
	if err == nil && adminCount == 0 {
		log.Println("Seeding Admin user into DB...")
		hashedPass, _ := bcrypt.GenerateFromPassword([]byte("SecurePass123!"), bcrypt.DefaultCost)
		_, _ = db.Exec(`
			INSERT INTO users (id, full_name, phone, password_hash, role, governorate, city, is_active, is_verified, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW(), NOW())
			ON CONFLICT DO NOTHING`,
			uuid.New(), "المدير العام للمنصة", "07801234567", string(hashedPass), "admin", "بغداد", "المنصور", true,
		)
	}

	// 5. Seed Default Brands if empty
	var brandCount int
	err = db.Get(&brandCount, "SELECT COUNT(*) FROM brands")
	if err == nil && brandCount == 0 {
		log.Println("Seeding Solar Brands into DB...")
		defaultBrands := []string{
			"LONGi Solar",
			"Deye",
			"Felicity Solar",
			"Huawei Solar",
			"Trina Solar",
			"Jinko Solar",
			"Growatt",
		}
		for _, bName := range defaultBrands {
			_, _ = db.Exec(`INSERT INTO brands (id, name, is_active, created_at, updated_at) VALUES ($1, $2, true, NOW(), NOW()) ON CONFLICT (name) DO NOTHING`, uuid.New(), bName)
		}
	}

	// 6. Seed Default Merchants & Stores if empty
	var storeCount int
	err = db.Get(&storeCount, "SELECT COUNT(*) FROM stores")
	if err == nil && storeCount == 0 {
		log.Println("Seeding Default Merchant Stores into DB...")
		hashedPass, _ := bcrypt.GenerateFromPassword([]byte("StorePass123!"), bcrypt.DefaultCost)

		merchant1ID := uuid.New()
		merchant2ID := uuid.New()

		_, _ = db.Exec(`
			INSERT INTO users (id, full_name, phone, password_hash, role, governorate, city, is_active, is_verified, created_at, updated_at)
			VALUES ($1, 'شركة بغداد للطاقة الشمولية', '07701112233', $2, 'merchant', 'بغداد', 'الكرادة', true, true, NOW(), NOW())
			ON CONFLICT DO NOTHING`, merchant1ID, string(hashedPass))

		_, _ = db.Exec(`
			INSERT INTO users (id, full_name, phone, password_hash, role, governorate, city, is_active, is_verified, created_at, updated_at)
			VALUES ($1, 'دجلة للحلول الشمسية الهجينة', '07704445566', $2, 'merchant', 'البصرة', 'العشار', true, true, NOW(), NOW())
			ON CONFLICT DO NOTHING`, merchant2ID, string(hashedPass))

		store1ID := uuid.New()
		store2ID := uuid.New()

		_, _ = db.Exec(`
			INSERT INTO stores (id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, rating, created_at, updated_at)
			VALUES ($1, $2, 'متجر بغداد للطاقة الشمولية', 'baghdad-solar-store', 'متجر متخصص بتقديم أحدث المنظومات الشمسية والألواح والبطاريات الهجينة ذات الكفاءة العالية.', 'assets/images/solar_panel_longi.jpg', 'assets/images/solar_panel_longi.jpg', '07701112233', true, true, 4.9, NOW(), NOW())
			ON CONFLICT DO NOTHING`, store1ID, merchant1ID)

		_, _ = db.Exec(`
			INSERT INTO stores (id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, rating, created_at, updated_at)
			VALUES ($1, $2, 'دجلة للحلول الشمسية الهجينة', 'tigris-solar-solutions', 'موزع معتمد لمنتجات داي وفيلستي ولونجي مع ضمان حقيقي وخدمات دعم فني متكاملة.', 'assets/images/solar_panel_longi.jpg', 'assets/images/solar_panel_longi.jpg', '07704445566', true, true, 4.8, NOW(), NOW())
			ON CONFLICT DO NOTHING`, store2ID, merchant2ID)

		_, _ = db.Exec(`UPDATE stores SET logo_url = 'assets/images/solar_panel_longi.jpg' WHERE logo_url IS NULL OR logo_url = ''`)
		_, _ = db.Exec(`UPDATE stores SET cover_url = 'assets/images/solar_panel_longi.jpg' WHERE cover_url IS NULL OR cover_url = ''`)

		// 7. Seed Default Solar Products if empty
		var prodCount int
		err = db.Get(&prodCount, "SELECT COUNT(*) FROM products")
		if err == nil && prodCount == 0 {
			log.Println("Seeding Solar Products into DB...")

			var longiBrandID, deyeBrandID, felicityBrandID uuid.UUID
			_ = db.Get(&longiBrandID, "SELECT id FROM brands WHERE name = 'LONGi Solar' LIMIT 1")
			_ = db.Get(&deyeBrandID, "SELECT id FROM brands WHERE name = 'Deye' LIMIT 1")
			_ = db.Get(&felicityBrandID, "SELECT id FROM brands WHERE name = 'Felicity Solar' LIMIT 1")

			var catPanel, catInverter, catBattery, catStructure, catCable int
			_ = db.Get(&catPanel, "SELECT id FROM categories WHERE name LIKE '%ألواح%' LIMIT 1")
			_ = db.Get(&catInverter, "SELECT id FROM categories WHERE name LIKE '%عواكس%' OR name LIKE '%انفيرتر%' LIMIT 1")
			_ = db.Get(&catBattery, "SELECT id FROM categories WHERE name LIKE '%بطاريات%' LIMIT 1")
			_ = db.Get(&catStructure, "SELECT id FROM categories WHERE name LIKE '%هياكل%' LIMIT 1")
			_ = db.Get(&catCable, "SELECT id FROM categories WHERE name LIKE '%كوابل%' LIMIT 1")

			if catPanel == 0 { catPanel = 1 }
			if catInverter == 0 { catInverter = 2 }
			if catBattery == 0 { catBattery = 3 }
			if catStructure == 0 { catStructure = 4 }
			if catCable == 0 { catCable = 5 }

			productsData := []struct {
				Name       string
				SKU        string
				Model      string
				Type       string
				CatID      int
				BrandID    *uuid.UUID
				StoreID    uuid.UUID
				MerchantID uuid.UUID
				PriceIQD   float64
				Stock      int
				Specs      string
				Images     string
			}{
				{
					Name:       "لوح طاقة شمسية LONGi 550W N-Type TOPCon",
					SKU:        "LONG-550W-N",
					Model:      "Hi-MO 6 TOPCon 550W",
					Type:       "panel",
					CatID:      catPanel,
					BrandID:    &longiBrandID,
					StoreID:    store1ID,
					MerchantID: merchant1ID,
					PriceIQD:   175000,
					Stock:      140,
					Specs:      `{"القدرة الاسمية": "550 Watt", "التكنولوجيا": "N-Type TOPCon Dual Glass", "الكفاءة": "22.5%", "الضمان": "25 سنة كفالة كفاءة وتوليد"}`,
					Images:     `{"assets/images/solar_panel_longi.jpg"}`,
				},
				{
					Name:       "انفيرتر هجين Deye 8kW Three Phase 48V",
					SKU:        "DEYE-INV-8KW-3P",
					Model:      "SUN-8K-SG04LP3-EU",
					Type:       "inverter",
					CatID:      catInverter,
					BrandID:    &deyeBrandID,
					StoreID:    store2ID,
					MerchantID: merchant2ID,
					PriceIQD:   1875000,
					Stock:      25,
					Specs:      `{"القدرة": "8000 Watt", "النظام": "Three Phase 48V Hybrid", "الكفاءة العظمى": "97.6%", "الضمان": "5 سنوات كفالة استبدال مصنعية"}`,
					Images:     `{"assets/images/solar_panel_longi.jpg"}`,
				},
				{
					Name:       "بطارية ليثيوم Felicity 10kWh LiFePO4 Wall Mount",
					SKU:        "FEL-BAT-10KW",
					Model:      "LPBF48200-N 51.2V 200Ah",
					Type:       "battery",
					CatID:      catBattery,
					BrandID:    &felicityBrandID,
					StoreID:    store1ID,
					MerchantID: merchant1ID,
					PriceIQD:   2450000,
					Stock:      18,
					Specs:      `{"السعة": "10.24 kWh (200Ah)", "النوع": "LiFePO4 الجدارية الذكية", "عدد الدورات": "6000+ Cycle", "الضمان": "10 سنوات ضمان حقيقي"}`,
					Images:     `{"assets/images/solar_panel_longi.jpg"}`,
				},
				{
					Name:       "هيكل تثبيت ألمنيوم مقاوم للرياح (4 ألواح)",
					SKU:        "ALU-STR-4P",
					Model:      "SOLAR-MOUNT-AL4",
					Type:       "structure",
					CatID:      catStructure,
					BrandID:    nil,
					StoreID:    store2ID,
					MerchantID: merchant2ID,
					PriceIQD:   95000,
					Stock:      80,
					Specs:      `{"المادة": "ألمنيوم AL6005-T5 وعوارض مجلفنة", "سعة الهيكل": "4 ألواح شمسية 550W", "الضمان": "15 سنة ضد الصدأ والرياح"}`,
					Images:     `{"assets/images/solar_panel_longi.jpg"}`,
				},
				{
					Name:       "كابل شمسي DC قياس 6mm2 مقاوم للشمس (100 متر)",
					SKU:        "CAB-DC-6MM",
					Model:      "SOLAR-CABLE-6MM2-100M",
					Type:       "cable",
					CatID:      catCable,
					BrandID:    nil,
					StoreID:    store1ID,
					MerchantID: merchant1ID,
					PriceIQD:   120000,
					Stock:      50,
					Specs:      `{"المواصفات": "نحاس ملقم مطلي بالقصدير IP67", "الطول": "لفة 100 متر", "الضمان": "20 سنة ضمان العزل"}`,
					Images:     `{"assets/images/solar_panel_longi.jpg"}`,
				},
			}

			for _, p := range productsData {
				var brandVal *uuid.UUID
				if p.BrandID != nil && *p.BrandID != uuid.Nil {
					brandVal = p.BrandID
				}
				_, _ = db.Exec(`
					INSERT INTO products (id, category_id, merchant_id, store_id, sku, name, brand_id, model, type, price_iqd, stock_quantity, specifications, images, is_available, created_at, updated_at)
					VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb, $13::text[], true, NOW(), NOW())
					ON CONFLICT DO NOTHING`,
					uuid.New(), p.CatID, p.MerchantID, p.StoreID, p.SKU, p.Name, brandVal, p.Model, p.Type, p.PriceIQD, p.Stock, p.Specs, p.Images,
				)
			}
		}
	}

	return nil
}
