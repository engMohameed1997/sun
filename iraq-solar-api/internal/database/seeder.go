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

	return nil
}
