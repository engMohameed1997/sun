package database

import (
	"encoding/json"
	"log"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

func SeedDatabase(db *sqlx.DB) error {
	if db == nil {
		return nil
	}

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

	// 2. Seed Default Test Admin & Customer User if empty
	var userCount int
	err = db.Get(&userCount, "SELECT COUNT(*) FROM users")
	if err == nil && userCount == 0 {
		log.Println("Seeding test users into DB...")
		hashedPass, _ := bcrypt.GenerateFromPassword([]byte("SecurePass123!"), bcrypt.DefaultCost)

		users := []struct {
			ID          uuid.UUID
			FullName    string
			Email       string
			Phone       string
			Role        string
			Governorate string
			City        string
		}{
			{uuid.New(), "أحمد المهندس", "ahmed.engineer@iraqsolar.iq", "07701234567", "customer", "Baghdad", "Karrada"},
			{uuid.New(), "المدير العام للمنصة", "admin@iraqsolar.iq", "07801234567", "admin", "Baghdad", "Mansour"},
			{uuid.New(), "شركة دجلة للطاقة", "merchant@iraqsolar.iq", "07501234567", "merchant", "Erbil", "Center"},
		}

		for _, u := range users {
			_, _ = db.Exec(`
				INSERT INTO users (id, full_name, email, phone, password_hash, role, governorate, city, is_active, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW(), NOW())
				ON CONFLICT DO NOTHING`,
				u.ID, u.FullName, u.Email, u.Phone, string(hashedPass), u.Role, u.Governorate, u.City,
			)
		}
	}

	// 3. Seed Products if empty
	var productCount int
	err = db.Get(&productCount, "SELECT COUNT(*) FROM products")
	if err == nil && productCount == 0 {
		log.Println("Seeding solar products catalog into DB...")

		panelSpecs, _ := json.Marshal(map[string]interface{}{"efficiency": "21.5%", "wattage": 550, "technology": "N-Type TOPCon", "warranty_yr": 25})
		inverterSpecs, _ := json.Marshal(map[string]interface{}{"capacity_kw": 8.0, "type": "Hybrid Three Phase", "mppt_channels": 2, "warranty_yr": 5})
		batterySpecs, _ := json.Marshal(map[string]interface{}{"capacity_kwh": 10.2, "chemistry": "LiFePO4", "cycles": 6000, "voltage": 48})

		products := []struct {
			SKU           string
			Name          string
			Brand         string
			Model         string
			Type          string
			PriceUSD      float64
			StockQuantity int
			Specs         []byte
		}{
			{"SP-LONGi-550", "لوح طاقة شمسية LONGi 550W N-Type TOPCon", "LONGi Solar", "LR5-72HTH-550M", "panel", 115.00, 150, panelSpecs},
			{"INV-DEYE-8K", "انفيرتر هجين Deye 8kW Three Phase 48V", "Deye", "SUN-8K-SG04LP3", "inverter", 1250.00, 25, inverterSpecs},
			{"BAT-FELICITY-10K", "بطارية ليثيوم Felicity 10.2kWh LiFePO4 48V", "FelicitySolar", "FL-LPBF48200-H", "battery", 1450.00, 30, batterySpecs},
			{"STR-ALUM-SYSTEM", "هيكل تثبيت ألمنيوم 10 ألواح شمسية مقاوم للرياح", "SolarRack Iraq", "SR-10P-AL", "structure", 180.00, 60, []byte("{}")},
			{"CBL-DC-6MM", "لفة كبل طاقة شمسية DC 6mm² نحاسي مجلفن 100م", "Kabelwerk", "KW-DC-6MM-100M", "cable", 85.00, 100, []byte("{}")},
		}

		for _, p := range products {
			_, _ = db.Exec(`
				INSERT INTO products (id, category_id, sku, name, brand, model, type, price_usd, stock_quantity, specifications, is_available, created_at, updated_at)
				VALUES ($1, 1, $2, $3, $4, $5, $6, $7, $8, $9, true, NOW(), NOW())
				ON CONFLICT DO NOTHING`,
				uuid.New(), p.SKU, p.Name, p.Brand, p.Model, p.Type, p.PriceUSD, p.StockQuantity, p.Specs,
			)
		}
	}

	return nil
}
