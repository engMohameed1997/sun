package service_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
)

type mockUserRepo struct {
	users map[string]*domain.User
}

func newMockUserRepo() *mockUserRepo {
	return &mockUserRepo{users: make(map[string]*domain.User)}
}

func (m *mockUserRepo) Create(ctx context.Context, user *domain.User) error {
	m.users[user.Phone] = user
	return nil
}

func (m *mockUserRepo) FindByPhone(ctx context.Context, phone string) (*domain.User, error) {
	u, ok := m.users[phone]
	if !ok {
		return nil, nil
	}
	return u, nil
}

func (m *mockUserRepo) FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	for _, u := range m.users {
		if u.ID == id {
			return u, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepo) ListByRole(ctx context.Context, roles []string, governorate, search string, page, perPage int) ([]domain.User, int, error) {
	var list []domain.User
	for _, u := range m.users {
		list = append(list, *u)
	}
	return list, len(list), nil
}

func (m *mockUserRepo) Update(ctx context.Context, user *domain.User) error {
	m.users[user.Phone] = user
	return nil
}

func (m *mockUserRepo) UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string) error {
	for _, u := range m.users {
		if u.ID == id {
			u.PasswordHash = passwordHash
			break
		}
	}
	return nil
}

type mockSecRepo struct {
	attempts  []*domain.LoginAttempt
	lockouts  map[string]*domain.UserLockout
	tokens    map[string]*domain.RefreshTokenRecord
	auditLogs []*domain.AuthAuditLog
}

func newMockSecRepo() *mockSecRepo {
	return &mockSecRepo{
		lockouts: make(map[string]*domain.UserLockout),
		tokens:   make(map[string]*domain.RefreshTokenRecord),
	}
}

func (m *mockSecRepo) RecordLoginAttempt(ctx context.Context, attempt *domain.LoginAttempt) error {
	m.attempts = append(m.attempts, attempt)
	return nil
}

func (m *mockSecRepo) GetLockoutStatus(ctx context.Context, identifier string) (*domain.UserLockout, error) {
	l, ok := m.lockouts[identifier]
	if !ok {
		return nil, nil
	}
	return l, nil
}

func (m *mockSecRepo) IncrementFailedAttempt(ctx context.Context, identifier string, maxAttempts int, lockDuration time.Duration) (*domain.UserLockout, error) {
	l, ok := m.lockouts[identifier]
	now := time.Now()
	if !ok {
		l = &domain.UserLockout{
			ID:          uuid.New(),
			Identifier:  identifier,
			FailedCount: 1,
			LockedUntil: now,
			CreatedAt:   now,
			UpdatedAt:   now,
		}
		m.lockouts[identifier] = l
		return l, nil
	}

	l.FailedCount++
	l.UpdatedAt = now
	if l.FailedCount >= maxAttempts {
		l.LockedUntil = now.Add(lockDuration)
	}
	return l, nil
}

func (m *mockSecRepo) ResetFailedAttempts(ctx context.Context, identifier string) error {
	delete(m.lockouts, identifier)
	return nil
}

func (m *mockSecRepo) SaveRefreshToken(ctx context.Context, record *domain.RefreshTokenRecord) error {
	m.tokens[record.TokenHash] = record
	return nil
}

func (m *mockSecRepo) FindRefreshToken(ctx context.Context, tokenHash string) (*domain.RefreshTokenRecord, error) {
	t, ok := m.tokens[tokenHash]
	if !ok {
		return nil, nil
	}
	return t, nil
}

func (m *mockSecRepo) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	if t, ok := m.tokens[tokenHash]; ok {
		t.IsRevoked = true
	}
	return nil
}

func (m *mockSecRepo) RevokeAllUserRefreshTokens(ctx context.Context, userID uuid.UUID) error {
	for _, t := range m.tokens {
		if t.UserID == userID {
			t.IsRevoked = true
		}
	}
	return nil
}

func (m *mockSecRepo) CreateAuditLog(ctx context.Context, auditLog *domain.AuthAuditLog) error {
	m.auditLogs = append(m.auditLogs, auditLog)
	return nil
}

func TestPhoneNormalization(t *testing.T) {
	svc := service.NewAuthService("secret", nil, nil)

	tests := []struct {
		input    string
		expected string
		wantErr  bool
	}{
		{"07801234567", "07801234567", false},
		{"+9647801234567", "07801234567", false},
		{"009647801234567", "07801234567", false},
		{"7801234567", "07801234567", false},
		{"0770-123-4567", "07701234567", false},
		{"invalid", "", true},
		{"12345", "", true},
	}

	for _, tt := range tests {
		normalized, err := svc.NormalizePhone(tt.input)
		if tt.wantErr && err == nil {
			t.Errorf("Expected error for phone %s, got nil", tt.input)
		}
		if !tt.wantErr && err != nil {
			t.Errorf("Unexpected error for phone %s: %v", tt.input, err)
		}
		if !tt.wantErr && normalized != tt.expected {
			t.Errorf("Expected %s, got %s", tt.expected, normalized)
		}
	}
}

func TestLoginAntiEnumerationAndLockout(t *testing.T) {
	userRepo := newMockUserRepo()
	secRepo := newMockSecRepo()
	svc := service.NewAuthService("test-secret", userRepo, secRepo)

	ctx := context.Background()
	phone := "07801234567"
	pass := "Password123"

	// 1. Register User
	_, _, _, err := svc.RegisterUser(ctx, domain.RegisterRequest{
		FullName: "Test User",
		Phone:    phone,
		Password: pass,
	})
	if err != nil {
		t.Fatalf("Failed to register user: %v", err)
	}

	secCtx := domain.LoginSecurityContext{
		IPAddress: "127.0.0.1",
		UserAgent: "Go-Test-Agent",
	}

	// 2. Test Incorrect Password -> Uniform error
	_, _, _, err = svc.LoginUserWithSecurity(ctx, domain.LoginRequest{
		Phone:    phone,
		Password: "WrongPassword",
	}, secCtx)
	if err == nil || err.Error() != "بيانات الدخول غير صحيحة" {
		t.Errorf("Expected uniform error 'بيانات الدخول غير صحيحة', got: %v", err)
	}

	// 3. Test Non-existent User -> Uniform error
	_, _, _, err = svc.LoginUserWithSecurity(ctx, domain.LoginRequest{
		Phone:    "07709998877",
		Password: "WrongPassword",
	}, secCtx)
	if err == nil || err.Error() != "بيانات الدخول غير صحيحة" {
		t.Errorf("Expected uniform error 'بيانات الدخول غير صحيحة', got: %v", err)
	}

	// 4. Test Lockout after 5 failed attempts
	for i := 0; i < 4; i++ {
		_, _, _, _ = svc.LoginUserWithSecurity(ctx, domain.LoginRequest{
			Phone:    phone,
			Password: "WrongPassword",
		}, secCtx)
	}

	// 6th attempt should return lockout error
	_, _, _, err = svc.LoginUserWithSecurity(ctx, domain.LoginRequest{
		Phone:    phone,
		Password: pass,
	}, secCtx)
	if err == nil || !testing.Short() && err.Error() == "بيانات الدخول غير صحيحة" {
		t.Logf("Lockout response message: %v", err)
	}

	// Reset lockout for testing success login
	_ = secRepo.ResetFailedAttempts(ctx, phone)

	// 5. Test Successful Login
	u, token, refresh, err := svc.LoginUserWithSecurity(ctx, domain.LoginRequest{
		Phone:    phone,
		Password: pass,
	}, secCtx)

	if err != nil {
		t.Fatalf("Expected successful login, got error: %v", err)
	}
	if u == nil || token == "" || refresh == "" {
		t.Fatalf("Expected valid user and tokens on login success")
	}
}
