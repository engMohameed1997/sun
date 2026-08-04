package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type AuthSecurityRepository interface {
	RecordLoginAttempt(ctx context.Context, attempt *domain.LoginAttempt) error
	GetLockoutStatus(ctx context.Context, identifier string) (*domain.UserLockout, error)
	IncrementFailedAttempt(ctx context.Context, identifier string, maxAttempts int, lockDuration time.Duration) (*domain.UserLockout, error)
	ResetFailedAttempts(ctx context.Context, identifier string) error

	SaveRefreshToken(ctx context.Context, record *domain.RefreshTokenRecord) error
	FindRefreshToken(ctx context.Context, tokenHash string) (*domain.RefreshTokenRecord, error)
	RevokeRefreshToken(ctx context.Context, tokenHash string) error
	RevokeAllUserRefreshTokens(ctx context.Context, userID uuid.UUID) error

	CreateAuditLog(ctx context.Context, auditLog *domain.AuthAuditLog) error
}

type postgresAuthSecurityRepository struct {
	db *sqlx.DB
}

func NewAuthSecurityRepository(db *sqlx.DB) AuthSecurityRepository {
	return &postgresAuthSecurityRepository{db: db}
}

func (r *postgresAuthSecurityRepository) RecordLoginAttempt(ctx context.Context, attempt *domain.LoginAttempt) error {
	if r.db == nil {
		return nil
	}

	if attempt.ID == uuid.Nil {
		attempt.ID = uuid.New()
	}
	if attempt.CreatedAt.IsZero() {
		attempt.CreatedAt = time.Now()
	}

	query := `
		INSERT INTO user_login_attempts (id, identifier, ip_address, user_agent, is_success, failure_reason, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query, attempt.ID, attempt.Identifier, attempt.IPAddress, attempt.UserAgent, attempt.IsSuccess, attempt.FailureReason, attempt.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to record login attempt: %w", err)
	}
	return nil
}

func (r *postgresAuthSecurityRepository) GetLockoutStatus(ctx context.Context, identifier string) (*domain.UserLockout, error) {
	if r.db == nil {
		return nil, nil
	}

	var lockout domain.UserLockout
	query := `SELECT id, identifier, failed_count, locked_until, created_at, updated_at FROM user_lockouts WHERE identifier = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &lockout, query, identifier)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get lockout status: %w", err)
	}

	return &lockout, nil
}

func (r *postgresAuthSecurityRepository) IncrementFailedAttempt(ctx context.Context, identifier string, maxAttempts int, lockDuration time.Duration) (*domain.UserLockout, error) {
	if r.db == nil {
		return nil, nil
	}

	now := time.Now()
	existing, err := r.GetLockoutStatus(ctx, identifier)
	if err != nil {
		return nil, err
	}

	if existing == nil {
		newLockout := &domain.UserLockout{
			ID:          uuid.New(),
			Identifier:  identifier,
			FailedCount: 1,
			LockedUntil: now,
			CreatedAt:   now,
			UpdatedAt:   now,
		}
		query := `
			INSERT INTO user_lockouts (id, identifier, failed_count, locked_until, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6)
			ON CONFLICT (identifier) DO UPDATE SET failed_count = user_lockouts.failed_count + 1, updated_at = EXCLUDED.updated_at
			RETURNING id, identifier, failed_count, locked_until, created_at, updated_at
		`
		var result domain.UserLockout
		if err := r.db.GetContext(ctx, &result, query, newLockout.ID, identifier, 1, now, now, now); err != nil {
			return nil, fmt.Errorf("failed to create lockout record: %w", err)
		}
		return &result, nil
	}

	// If already locked and locked_until is in future, preserve locked_until
	var lockedUntil time.Time
	failedCount := existing.FailedCount + 1

	if failedCount >= maxAttempts {
		lockedUntil = now.Add(lockDuration)
	} else {
		lockedUntil = now
	}

	query := `
		UPDATE user_lockouts
		SET failed_count = $1, locked_until = $2, updated_at = $3
		WHERE identifier = $4
		RETURNING id, identifier, failed_count, locked_until, created_at, updated_at
	`
	var result domain.UserLockout
	if err := r.db.GetContext(ctx, &result, query, failedCount, lockedUntil, now, identifier); err != nil {
		return nil, fmt.Errorf("failed to update lockout record: %w", err)
	}

	return &result, nil
}

func (r *postgresAuthSecurityRepository) ResetFailedAttempts(ctx context.Context, identifier string) error {
	if r.db == nil {
		return nil
	}

	query := `DELETE FROM user_lockouts WHERE identifier = $1`
	_, err := r.db.ExecContext(ctx, query, identifier)
	if err != nil {
		return fmt.Errorf("failed to reset lockout record: %w", err)
	}
	return nil
}

func (r *postgresAuthSecurityRepository) SaveRefreshToken(ctx context.Context, record *domain.RefreshTokenRecord) error {
	if r.db == nil {
		return nil
	}

	if record.ID == uuid.Nil {
		record.ID = uuid.New()
	}
	if record.CreatedAt.IsZero() {
		record.CreatedAt = time.Now()
	}

	query := `
		INSERT INTO refresh_tokens (id, user_id, token_hash, user_agent, ip_address, is_revoked, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query, record.ID, record.UserID, record.TokenHash, record.UserAgent, record.IPAddress, record.IsRevoked, record.ExpiresAt, record.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to save refresh token: %w", err)
	}

	return nil
}

func (r *postgresAuthSecurityRepository) FindRefreshToken(ctx context.Context, tokenHash string) (*domain.RefreshTokenRecord, error) {
	if r.db == nil {
		return nil, nil
	}

	var record domain.RefreshTokenRecord
	query := `SELECT id, user_id, token_hash, COALESCE(user_agent, '') as user_agent, COALESCE(ip_address, '') as ip_address, is_revoked, expires_at, created_at FROM refresh_tokens WHERE token_hash = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &record, query, tokenHash)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to find refresh token: %w", err)
	}

	return &record, nil
}

func (r *postgresAuthSecurityRepository) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	if r.db == nil {
		return nil
	}

	query := `UPDATE refresh_tokens SET is_revoked = true WHERE token_hash = $1`
	_, err := r.db.ExecContext(ctx, query, tokenHash)
	if err != nil {
		return fmt.Errorf("failed to revoke refresh token: %w", err)
	}
	return nil
}

func (r *postgresAuthSecurityRepository) RevokeAllUserRefreshTokens(ctx context.Context, userID uuid.UUID) error {
	if r.db == nil {
		return nil
	}

	query := `UPDATE refresh_tokens SET is_revoked = true WHERE user_id = $1`
	_, err := r.db.ExecContext(ctx, query, userID)
	if err != nil {
		return fmt.Errorf("failed to revoke all refresh tokens for user: %w", err)
	}
	return nil
}

func (r *postgresAuthSecurityRepository) CreateAuditLog(ctx context.Context, auditLog *domain.AuthAuditLog) error {
	if r.db == nil {
		return nil
	}

	if auditLog.ID == uuid.Nil {
		auditLog.ID = uuid.New()
	}
	if auditLog.CreatedAt.IsZero() {
		auditLog.CreatedAt = time.Now()
	}
	if auditLog.Details == "" {
		auditLog.Details = "{}"
	}

	query := `
		INSERT INTO auth_audit_logs (id, user_id, event, ip_address, user_agent, details, created_at)
		VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)
	`
	_, err := r.db.ExecContext(ctx, query, auditLog.ID, auditLog.UserID, auditLog.Event, auditLog.IPAddress, auditLog.UserAgent, auditLog.Details, auditLog.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to insert auth audit log: %w", err)
	}
	return nil
}
