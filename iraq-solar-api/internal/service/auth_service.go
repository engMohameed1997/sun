package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type AuthService struct {
	jwtSecret string
	userRepo  repository.UserRepository
	secRepo   repository.AuthSecurityRepository
	dummyHash string
}

func NewAuthService(jwtSecret string, userRepo repository.UserRepository, secRepo repository.AuthSecurityRepository) *AuthService {
	dummyBytes, _ := bcrypt.GenerateFromPassword([]byte("dummy_password_for_timing_mitigation"), bcrypt.DefaultCost)
	return &AuthService{
		jwtSecret: jwtSecret,
		userRepo:  userRepo,
		secRepo:   secRepo,
		dummyHash: string(dummyBytes),
	}
}

func (s *AuthService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func (s *AuthService) CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

type Claims struct {
	UserID uuid.UUID   `json:"user_id"`
	Phone  string      `json:"phone"`
	Role   domain.Role `json:"role"`
	jwt.RegisteredClaims
}

func (s *AuthService) GenerateToken(user *domain.User) (string, string, error) {
	// Access Token: Short-lived (30 minutes)
	expirationTime := time.Now().Add(30 * time.Minute)
	claims := &Claims{
		UserID: user.ID,
		Phone:  user.Phone,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.ID.String(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", "", err
	}

	// Refresh token valid for 3 months (90 days)
	refreshExpiration := time.Now().Add(90 * 24 * time.Hour)
	refreshClaims := &Claims{
		UserID: user.ID,
		Phone:  user.Phone,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(refreshExpiration),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.ID.String(),
		},
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", "", err
	}

	return tokenString, refreshTokenString, nil
}

func (s *AuthService) NormalizePhone(phone string) (string, error) {
	cleaned := strings.TrimSpace(phone)
	if cleaned == "" {
		return "", errors.New("يرجى إدخال رقم الهاتف")
	}

	r := strings.NewReplacer(" ", "", "-", "", "(", "", ")", "", "+", "")
	cleaned = r.Replace(cleaned)

	if strings.HasPrefix(cleaned, "00964") {
		cleaned = strings.TrimPrefix(cleaned, "00964")
		cleaned = "0" + cleaned
	} else if strings.HasPrefix(cleaned, "964") {
		cleaned = strings.TrimPrefix(cleaned, "964")
		cleaned = "0" + cleaned
	} else if len(cleaned) == 10 && (strings.HasPrefix(cleaned, "77") || strings.HasPrefix(cleaned, "78") || strings.HasPrefix(cleaned, "79") || strings.HasPrefix(cleaned, "75") || strings.HasPrefix(cleaned, "73") || strings.HasPrefix(cleaned, "74") || strings.HasPrefix(cleaned, "76")) {
		cleaned = "0" + cleaned
	}

	matched, _ := regexp.MatchString(`^07[3-9]\d{8}$`, cleaned)
	if !matched {
		return "", errors.New("رقم الهاتف غير صحيح. يجب أن يبدأ بـ 07 ويتكون من 11 رقماً (مثال: 07801234567)")
	}

	return cleaned, nil
}

func (s *AuthService) RefreshToken(refreshTokenStr string) (string, string, error) {
	return s.RefreshTokenWithSecurity(context.Background(), refreshTokenStr, domain.LoginSecurityContext{})
}

func (s *AuthService) RefreshTokenWithSecurity(ctx context.Context, refreshTokenStr string, secContext domain.LoginSecurityContext) (string, string, error) {
	claims, err := s.ValidateToken(refreshTokenStr)
	if err != nil {
		return "", "", errors.New("رمز التجديد غير صالح أو منتهي الصلاحية")
	}

	tokenHash := sha256Hash(refreshTokenStr)
	if s.secRepo != nil {
		record, err := s.secRepo.FindRefreshToken(ctx, tokenHash)
		if err != nil || record == nil || record.IsRevoked || time.Now().After(record.ExpiresAt) {
			return "", "", errors.New("رمز التجديد غير صالح، ملغى، أو منتهي الصلاحية")
		}
		_ = s.secRepo.RevokeRefreshToken(ctx, tokenHash)
	}

	var user *domain.User
	if s.userRepo != nil {
		user, err = s.userRepo.FindByID(ctx, claims.UserID)
		if err != nil || user == nil {
			return "", "", errors.New("المستخدم غير موجود")
		}
		if !user.IsActive {
			return "", "", errors.New("الحساب معطل")
		}
	} else {
		user = &domain.User{
			ID:       claims.UserID,
			Phone:    claims.Phone,
			Role:     claims.Role,
			IsActive: true,
		}
	}

	newToken, newRefreshToken, err := s.GenerateToken(user)
	if err != nil {
		return "", "", err
	}

	if s.secRepo != nil {
		newTokenHash := sha256Hash(newRefreshToken)
		_ = s.secRepo.SaveRefreshToken(ctx, &domain.RefreshTokenRecord{
			ID:        uuid.New(),
			UserID:    user.ID,
			TokenHash: newTokenHash,
			UserAgent: secContext.UserAgent,
			IPAddress: secContext.IPAddress,
			IsRevoked: false,
			ExpiresAt: time.Now().Add(90 * 24 * time.Hour),
		})
	}

	return newToken, newRefreshToken, nil
}

func (s *AuthService) LogoutUser(ctx context.Context, refreshTokenStr string) error {
	if refreshTokenStr == "" || s.secRepo == nil {
		return nil
	}
	tokenHash := sha256Hash(refreshTokenStr)
	return s.secRepo.RevokeRefreshToken(ctx, tokenHash)
}

func (s *AuthService) ValidateToken(tokenStr string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.jwtSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, errors.New("invalid or expired token")
	}

	return claims, nil
}

func (s *AuthService) ValidateTokenWithContext(ctx context.Context, tokenStr string) (*Claims, error) {
	claims, err := s.ValidateToken(tokenStr)
	if err != nil {
		return nil, err
	}

	if s.userRepo != nil {
		user, err := s.userRepo.FindByID(ctx, claims.UserID)
		if err == nil && user != nil {
			if !user.IsActive {
				return nil, errors.New("الحساب معطل أو محظور من قبل الإدارة")
			}
		}
	}

	return claims, nil
}

func (s *AuthService) RegisterUser(ctx context.Context, req domain.RegisterRequest) (*domain.User, string, string, error) {
	phone, err := s.NormalizePhone(req.Phone)
	if err != nil {
		return nil, "", "", err
	}

	if len(req.Password) < 6 {
		return nil, "", "", errors.New("كلمة المرور يجب أن تكون 6 أحرف على الأقل")
	}

	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		fullName = "زبون منصة الشمسية"
	}

	if s.userRepo != nil {
		existing, err := s.userRepo.FindByPhone(ctx, phone)
		if err == nil && existing != nil {
			return nil, "", "", errors.New("رقم الهاتف مستخدم بالفعل، يرجى تسجيل الدخول")
		}
	}

	hashedPassword, err := s.HashPassword(req.Password)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to hash password: %w", err)
	}

	role := req.Role
	if role == "" {
		role = domain.RoleCustomer
	}

	var govID *int
	if req.GovernorateID != nil && *req.GovernorateID > 0 {
		govID = req.GovernorateID
	}
	var distID *int
	if req.DistrictID != nil && *req.DistrictID > 0 {
		distID = req.DistrictID
	}

	newUser := &domain.User{
		ID:            uuid.New(),
		FullName:      fullName,
		Phone:         phone,
		PasswordHash:  hashedPassword,
		Role:          role,
		GovernorateID: govID,
		DistrictID:    distID,
		Governorate:   req.Governorate,
		City:          req.City,
		Landmark:      req.Landmark,
		IsActive:      true,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if s.userRepo != nil {
		if err := s.userRepo.Create(ctx, newUser); err != nil {
			return nil, "", "", fmt.Errorf("failed to create user in database: %w", err)
		}
	}

	token, refreshToken, err := s.GenerateToken(newUser)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate tokens: %w", err)
	}

	return newUser, token, refreshToken, nil
}

func (s *AuthService) LoginUser(ctx context.Context, req domain.LoginRequest) (*domain.User, string, string, error) {
	return s.LoginUserWithSecurity(ctx, req, domain.LoginSecurityContext{})
}

func (s *AuthService) LoginUserWithSecurity(ctx context.Context, req domain.LoginRequest, secContext domain.LoginSecurityContext) (*domain.User, string, string, error) {
	phone, err := s.NormalizePhone(req.Phone)
	if err != nil {
		return nil, "", "", err
	}

	ipAddr := strings.TrimSpace(secContext.IPAddress)
	if ipAddr == "" {
		ipAddr = "unknown"
	}
	userAgent := strings.TrimSpace(secContext.UserAgent)

	// Check Account/IP Lockout
	if s.secRepo != nil {
		lockout, err := s.secRepo.GetLockoutStatus(ctx, phone)
		if err == nil && lockout != nil && lockout.LockedUntil.After(time.Now()) {
			remaining := time.Until(lockout.LockedUntil).Minutes()
			_ = s.secRepo.CreateAuditLog(ctx, &domain.AuthAuditLog{
				Event:     "LOGIN_BLOCKED_LOCKOUT",
				IPAddress: ipAddr,
				UserAgent: userAgent,
				Details:   fmt.Sprintf(`{"identifier":"%s","locked_until":"%s"}`, phone, lockout.LockedUntil.Format(time.RFC3339)),
			})
			return nil, "", "", fmt.Errorf("الحساب محظور مؤقتاً بسبب تكرار المحاولات الفاشلة. يرجى المحاولة بعد %.0f دقيقة", remaining+1)
		}
	}

	var user *domain.User
	if s.userRepo != nil {
		user, err = s.userRepo.FindByPhone(ctx, phone)
		if err != nil {
			return nil, "", "", fmt.Errorf("database query error: %w", err)
		}
	}

	passwordValid := false
	if user != nil && user.PasswordHash != "" {
		passwordValid = s.CheckPassword(req.Password, user.PasswordHash)
	} else {
		// Dummy check for constant time execution against timing attacks & user enumeration
		_ = bcrypt.CompareHashAndPassword([]byte(s.dummyHash), []byte(req.Password))
	}

	if user == nil || !passwordValid {
		if s.secRepo != nil {
			_, _ = s.secRepo.IncrementFailedAttempt(ctx, phone, 5, 15*time.Minute)
			_ = s.secRepo.RecordLoginAttempt(ctx, &domain.LoginAttempt{
				Identifier:    phone,
				IPAddress:     ipAddr,
				UserAgent:     userAgent,
				IsSuccess:     false,
				FailureReason: "INVALID_CREDENTIALS",
			})
			_ = s.secRepo.CreateAuditLog(ctx, &domain.AuthAuditLog{
				Event:     "LOGIN_FAILED",
				IPAddress: ipAddr,
				UserAgent: userAgent,
				Details:   fmt.Sprintf(`{"identifier":"%s"}`, phone),
			})
		}
		// Generic message to prevent user enumeration
		return nil, "", "", errors.New("بيانات الدخول غير صحيحة")
	}

	if !user.IsActive {
		if s.secRepo != nil {
			_ = s.secRepo.RecordLoginAttempt(ctx, &domain.LoginAttempt{
				Identifier:    phone,
				IPAddress:     ipAddr,
				UserAgent:     userAgent,
				IsSuccess:     false,
				FailureReason: "ACCOUNT_DISABLED",
			})
		}
		return nil, "", "", errors.New("الحساب معطل أو محظور من قبل الإدارة")
	}

	// Login Success: Reset lockout & record success
	if s.secRepo != nil {
		_ = s.secRepo.ResetFailedAttempts(ctx, phone)
		_ = s.secRepo.RecordLoginAttempt(ctx, &domain.LoginAttempt{
			Identifier: phone,
			IPAddress:  ipAddr,
			UserAgent:  userAgent,
			IsSuccess:  true,
		})
		userID := user.ID
		_ = s.secRepo.CreateAuditLog(ctx, &domain.AuthAuditLog{
			UserID:    &userID,
			Event:     "LOGIN_SUCCESS",
			IPAddress: ipAddr,
			UserAgent: userAgent,
			Details:   fmt.Sprintf(`{"user_id":"%s"}`, user.ID.String()),
		})
	}

	token, refreshToken, err := s.GenerateToken(user)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate tokens: %w", err)
	}

	if s.secRepo != nil {
		tokenHash := sha256Hash(refreshToken)
		_ = s.secRepo.SaveRefreshToken(ctx, &domain.RefreshTokenRecord{
			ID:        uuid.New(),
			UserID:    user.ID,
			TokenHash: tokenHash,
			UserAgent: userAgent,
			IPAddress: ipAddr,
			IsRevoked: false,
			ExpiresAt: time.Now().Add(90 * 24 * time.Hour),
		})
	}

	return user, token, refreshToken, nil
}

func sha256Hash(str string) string {
	sum := sha256.Sum256([]byte(str))
	return hex.EncodeToString(sum[:])
}
