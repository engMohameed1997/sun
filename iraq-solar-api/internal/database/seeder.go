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

	// Seed Admin User ONLY if no admin exists
	var adminCount int
	err = db.Get(&adminCount, "SELECT COUNT(*) FROM users WHERE role = 'admin'")
	if err == nil && adminCount == 0 {
		log.Println("Seeding Admin user into DB...")
		hashedPass, _ := bcrypt.GenerateFromPassword([]byte("SecurePass123!"), bcrypt.DefaultCost)
		_, _ = db.Exec(`
			INSERT INTO users (id, full_name, email, phone, password_hash, role, governorate, city, is_active, is_verified, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, true, NOW(), NOW())
			ON CONFLICT DO NOTHING`,
			uuid.New(), "المدير العام للمنصة", "admin@iraqsolar.iq", "07801234567", string(hashedPass), "admin", "Baghdad", "Mansour",
		)
	}

	return nil
}
