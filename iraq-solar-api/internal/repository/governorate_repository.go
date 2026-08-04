package repository

import (
	"context"
	"database/sql"

	"github.com/jmoiron/sqlx"
	"github.com/iraq-solar/api/internal/domain"
)

type GovernorateRepository struct {
	db *sqlx.DB
}

func NewGovernorateRepository(db *sqlx.DB) *GovernorateRepository {
	return &GovernorateRepository{db: db}
}

func (r *GovernorateRepository) List(ctx context.Context) ([]domain.Governorate, error) {
	if r.db == nil {
		return getFallbackGovernorates(), nil
	}
	var governorates []domain.Governorate
	err := r.db.SelectContext(ctx, &governorates, "SELECT id, name_ar, name_en, is_active, created_at FROM governorates WHERE is_active = true ORDER BY id ASC")
	if err != nil || len(governorates) == 0 {
		return getFallbackGovernorates(), nil
	}
	return governorates, nil
}

func (r *GovernorateRepository) GetByID(ctx context.Context, id int) (*domain.Governorate, error) {
	if r.db == nil {
		govs := getFallbackGovernorates()
		for _, g := range govs {
			if g.ID == id {
				return &g, nil
			}
		}
		return nil, nil
	}
	var g domain.Governorate
	err := r.db.GetContext(ctx, &g, "SELECT id, name_ar, name_en, is_active, created_at FROM governorates WHERE id = $1", id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &g, err
}

func (r *GovernorateRepository) Create(ctx context.Context, g *domain.Governorate) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO governorates (name_ar, name_en, is_active) 
              VALUES ($1, $2, $3) RETURNING id, created_at`
	return r.db.QueryRowContext(ctx, query, g.NameAr, g.NameEn, g.IsActive).Scan(&g.ID, &g.CreatedAt)
}

func (r *GovernorateRepository) Update(ctx context.Context, id int, nameAr, nameEn string) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE governorates SET name_ar = $1, name_en = $2 WHERE id = $3", nameAr, nameEn, id)
	return err
}

func (r *GovernorateRepository) ToggleActive(ctx context.Context, id int, isActive bool) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE governorates SET is_active = $1 WHERE id = $2", isActive, id)
	return err
}

func (r *GovernorateRepository) Delete(ctx context.Context, id int) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM governorates WHERE id = $1", id)
	return err
}

func (r *GovernorateRepository) ListDistrictsByGovernorate(ctx context.Context, governorateID int) ([]domain.District, error) {
	if r.db == nil {
		return getFallbackDistricts(governorateID), nil
	}
	var districts []domain.District
	query := `SELECT id, governorate_id, name_ar, name_en, is_active, created_at FROM districts WHERE governorate_id = $1 AND is_active = true ORDER BY name_ar ASC`
	err := r.db.SelectContext(ctx, &districts, query, governorateID)
	if err != nil || len(districts) == 0 {
		return getFallbackDistricts(governorateID), nil
	}
	return districts, nil
}

func getFallbackGovernorates() []domain.Governorate {
	govs := []struct {
		id int
		ar string
		en string
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
	result := make([]domain.Governorate, len(govs))
	for i, g := range govs {
		result[i] = domain.Governorate{
			ID:       g.id,
			NameAr:   g.ar,
			NameEn:   g.en,
			IsActive: true,
		}
	}
	return result
}

func getFallbackDistricts(govID int) []domain.District {
	var list []struct {
		id int
		ar string
		en string
	}
	switch govID {
	case 1: // Baghdad
		list = []struct{ id int; ar, en string }{
			{101, "الكرادة / الجادرية", "Karrada / Jadriya"},
			{102, "المنصور / اليرموك", "Mansour / Yarmouk"},
			{103, "الأعظمية / الصليخ", "Adhamiya / Slaikh"},
			{104, "شارع فلسطين / زيونة", "Palestine Street / Zayouna"},
			{105, "الكاظمية المقدسة", "Kadhimiya"},
			{106, "الدورة / السيدية", "Dora / Saydiya"},
			{107, "العامرية / الغزالية", "Amiriya / Ghazaliya"},
			{108, "بغداد الجديدة / الغدير", "New Baghdad / Ghadir"},
			{109, "الشعب / البنوك", "Shaab / Banook"},
			{110, "أبو غريب", "Abu Ghraib"},
			{111, "التاجي", "Taji"},
			{112, "المحمودية", "Mahmudiya"},
			{113, "مدينة الصدر", "Sadr City"},
		}
	case 2: // Basra
		list = []struct{ id int; ar, en string }{
			{201, "مركز البصرة / العشار", "Basra Center / Ashar"},
			{202, "المعقل / الجبيلة", "Maqil / Jubaila"},
			{203, "الزبير", "Al-Zubair"},
			{204, "الهارثة / القرنة", "Hartha / Qurna"},
			{205, "شط العرب / الطويسة", "Shatt Al-Arab"},
			{206, "أبو الخصيب", "Abu Al-Khaseeb"},
			{207, "الفاو", "Al-Faw"},
		}
	case 3: // Nineveh
		list = []struct{ id int; ar, en string }{
			{301, "الموصل - الساحل الأيسر (الزهور / الزراعي)", "Mosul Left Bank"},
			{302, "الموصل - الساحل الأيمن (الدواسة / الدواجن)", "Mosul Right Bank"},
			{303, "تلعفر", "Tel Afar"},
			{304, "حمدانية / برطلة", "Hamdaniya / Bartella"},
			{305, "سنجار", "Sinjar"},
			{306, "شيخان", "Shekhan"},
		}
	case 4: // Erbil
		list = []struct{ id int; ar, en string }{
			{401, "مركز أربيل / شورتة", "Erbil Center"},
			{402, "عينكاوة", "Ankawa"},
			{403, "شارع 100م / 60م", "100m Street"},
			{404, "سوران", "Soran"},
			{405, "شقلاوة", "Shaqlawa"},
		}
	case 5: // Babil
		list = []struct{ id int; ar, en string }{
			{501, "الحلة - المركز (شارع 40 / نادر)", "Hilla Center"},
			{502, "المحاويل", "Al-Mahawil"},
			{503, "المسيب", "Al-Musayab"},
			{504, "القاسم", "Al-Qasim"},
			{505, "الهاشمية", "Al-Hashimiya"},
		}
	case 6: // Dhi Qar
		list = []struct{ id int; ar, en string }{
			{601, "الناصرية - المركز (شوملي / الحبوبي)", "Nasiriyah Center"},
			{602, "الشطرة", "Al-Shatrah"},
			{603, "الرفاعي", "Al-Rifai"},
			{604, "سوق الشيوخ", "Suq Al-Shuyukh"},
		}
	case 7: // Sulaymaniyah
		list = []struct{ id int; ar, en string }{
			{701, "السليمانية - المركز (عقاري / مجيد آوا)", "Sulaymaniyah Center"},
			{702, "جمجمال", "Chamchamal"},
			{703, "كلار", "Kalar"},
			{704, "رانية", "Ranya"},
		}
	case 8: // Diyala
		list = []struct{ id int; ar, en string }{
			{801, "بعقوبة - المركز (التحرير / العصري)", "Baqubah Center"},
			{802, "المقدادية", "Muqdadiya"},
			{803, "خانقين", "Khanaqin"},
			{804, "الخالص", "Al-Khalis"},
		}
	case 9: // Anbar
		list = []struct{ id int; ar, en string }{
			{901, "الرمادي - المركز (شارع 17 / التأميم)", "Ramadi Center"},
			{902, "الفلوجة - المركز (الجمهورية / الجولان)", "Fallujah Center"},
			{903, "هيت", "Heet"},
			{904, "القائم", "Al-Qaim"},
		}
	case 10: // Maysan
		list = []struct{ id int; ar, en string }{
			{1001, "العمارة - المركز (القطاع / العرضات)", "Amarah Center"},
			{1002, "المجر الكبير", "Al-Majar Al-Kabeer"},
			{1003, "علي الغربي", "Ali Al-Gharbi"},
		}
	case 11: // Najaf
		list = []struct{ id int; ar, en string }{
			{1101, "النجف - المركز (الروان / الغدير)", "Najaf Center"},
			{1102, "الكوفة المقدسة", "Kufa"},
			{1103, "المناذرة", "Al-Manathera"},
		}
	case 12: // Karbala
		list = []struct{ id int; ar, en string }{
			{1201, "كربلاء - المركز (البلدية / الحسين)", "Karbala Center"},
			{1202, "الهندية / طويريج", "Al-Hindiya"},
			{1203, "عين التمر", "Ain Al-Tamur"},
		}
	case 13: // Kirkuk
		list = []struct{ id int; ar, en string }{
			{1301, "كركوك - المركز (طريق بغداد / رحيماوا)", "Kirkuk Center"},
			{1302, "الحويجة", "Al-Hawija"},
			{1303, "دبس", "Daqoq"},
		}
	case 14: // Saladin
		list = []struct{ id int; ar, en string }{
			{1401, "تكريت - المركز (القادسية / الزهور)", "Tikrit Center"},
			{1402, "سامراء المقدسة", "Samarra"},
			{1403, "بلد / الدجيل", "Balad / Dujail"},
		}
	case 15: // Diwaniyah
		list = []struct{ id int; ar, en string }{
			{1501, "الديوانية - المركز (الجديدة / الجزائر)", "Diwaniyah Center"},
			{1502, "عفك", "Afaq"},
			{1503, "الشامية", "Al-Shamiya"},
		}
	case 16: // Wasit
		list = []struct{ id int; ar, en string }{
			{1601, "الكوت - المركز (الهورة / الزهراء)", "Kut Center"},
			{1602, "الحي", "Al-Hayy"},
			{1603, "النعمانية", "Al-Numaniya"},
		}
	case 17: // Duhok
		list = []struct{ id int; ar, en string }{
			{1701, "دهوك - المركز (ماسيك / مالطا)", "Duhok Center"},
			{1702, "زاخو", "Zakho"},
			{1703, "ئامێدی / العمادية", "Amadiya"},
		}
	case 18: // Muthanna
		list = []struct{ id int; ar, en string }{
			{1801, "السماوة - المركز (الشرقي / العسكري)", "Samawah Center"},
			{1802, "الرميثة", "Al-Rumaitha"},
		}
	default:
		list = []struct{ id int; ar, en string }{
			{govID*100 + 1, "مركز المحافظة / الحي الرئيسي", "City Center"},
			{govID*100 + 2, "الناحية الأولى / المناطق الحضرية", "District Area 1"},
			{govID*100 + 3, "الناحية الثانية / الشارع العام", "District Area 2"},
		}
	}

	districts := make([]domain.District, len(list))
	for i, d := range list {
		districts[i] = domain.District{
			ID:            d.id,
			GovernorateID: govID,
			NameAr:        d.ar,
			NameEn:        d.en,
			IsActive:      true,
		}
	}
	return districts
}
