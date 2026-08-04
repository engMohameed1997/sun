package utils

import (
	"html"
	"regexp"
	"strings"

	"github.com/google/uuid"
)

var (
	iraqPhoneRegex = regexp.MustCompile(`^07[3-9]\d{8}$`)
)

// SanitizeString — تنظيف النصوص من أي رموز HTML أو سكريبتات خبيثة (Requirement 2)
func SanitizeString(input string) string {
	trimmed := strings.TrimSpace(input)
	// الهروب من رموز HTML الممكن استخدامها في XSS
	escaped := html.EscapeString(trimmed)
	return escaped
}

// IsValidIraqiPhone — التحقق الحارم من رقم الهاتف العراقي (07xxxxxxxxx)
func IsValidIraqiPhone(phone string) bool {
	clean := strings.TrimSpace(phone)
	return iraqPhoneRegex.MatchString(clean)
}

// IsValidUUID — التحقق من صحة المعرف UUID
func IsValidUUID(id string) bool {
	_, err := uuid.Parse(strings.TrimSpace(id))
	return err == nil
}

// ClampInt — تقييد القيم الرقمية بين حد أدنى وأقصى
func ClampInt(val, min, max int) int {
	if val < min {
		return min
	}
	if val > max {
		return max
	}
	return val
}
