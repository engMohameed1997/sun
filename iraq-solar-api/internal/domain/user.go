package domain

import (
	"time"

	"github.com/google/uuid"
)

type Role string

const (
	RoleAdmin     Role = "admin"
	RoleCustomer  Role = "customer"
	RoleEngineer  Role = "engineer"
	RoleInstaller Role = "installer"
	RoleMerchant  Role = "merchant"
)

type User struct {
	ID            uuid.UUID  `db:"id" json:"id"`
	FullName      string     `db:"full_name" json:"full_name"`
	Phone         string     `db:"phone" json:"phone"`
	PasswordHash  string     `db:"password_hash" json:"-"`
	Role          Role       `db:"role" json:"role"`
	GovernorateID *int       `db:"governorate_id" json:"governorate_id,omitempty"`
	DistrictID    *int       `db:"district_id" json:"district_id,omitempty"`
	Governorate   string     `db:"governorate" json:"governorate"`
	City          string     `db:"city" json:"city"`
	Landmark      string     `db:"landmark" json:"landmark"`
	IsActive      bool       `db:"is_active" json:"is_active"`
	IsVerified    bool       `db:"is_verified" json:"is_verified"`
	VerifiedAt    *time.Time `db:"verified_at" json:"verified_at,omitempty"`
	VerifiedBy    *uuid.UUID `db:"verified_by" json:"verified_by,omitempty"`
	CreatedAt     time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt     time.Time  `db:"updated_at" json:"updated_at"`
	DeletedAt     *time.Time `db:"deleted_at" json:"deleted_at,omitempty"`
}

type District struct {
	ID            int       `db:"id" json:"id"`
	GovernorateID int       `db:"governorate_id" json:"governorate_id"`
	NameAr        string    `db:"name_ar" json:"name_ar"`
	NameEn        string    `db:"name_en" json:"name_en"`
	IsActive      bool      `db:"is_active" json:"is_active"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`
}

type RegisterRequest struct {
	FullName      string `json:"full_name" binding:"required"`
	Phone         string `json:"phone" binding:"required"`
	Password      string `json:"password" binding:"required"`
	GovernorateID *int   `json:"governorate_id"`
	DistrictID    *int   `json:"district_id"`
	Governorate   string `json:"governorate"`
	City          string `json:"city"`
	Landmark      string `json:"landmark"`
	Role          Role   `json:"role"`
}

type LoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}
