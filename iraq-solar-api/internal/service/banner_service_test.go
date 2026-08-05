package service_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
)

func TestIsBannerActiveNow(t *testing.T) {
	svc := service.NewBannerService(nil, nil, 300)

	loc, _ := time.LoadLocation("Asia/Baghdad")
	now := time.Date(2026, 8, 4, 14, 0, 0, 0, loc)

	t.Run("Active banner within date range", func(t *testing.T) {
		starts := now.Add(-1 * time.Hour)
		ends := now.Add(1 * time.Hour)
		b := &domain.Banner{
			IsActive: true,
			StartsAt: &starts,
			EndsAt:   &ends,
			Timezone: "Asia/Baghdad",
		}
		if !svc.IsBannerActiveNow(b, now) {
			t.Errorf("Expected banner to be active")
		}
	})

	t.Run("Inactive banner outside date range", func(t *testing.T) {
		starts := now.Add(1 * time.Hour)
		ends := now.Add(2 * time.Hour)
		b := &domain.Banner{
			IsActive: true,
			StartsAt: &starts,
			EndsAt:   &ends,
			Timezone: "Asia/Baghdad",
		}
		if svc.IsBannerActiveNow(b, now) {
			t.Errorf("Expected banner to be inactive (starts in future)")
		}
	})

	t.Run("Daily recurrence active time check", func(t *testing.T) {
		recTime := "08:00"
		b := &domain.Banner{
			IsActive:       true,
			RecurrenceType: domain.RecurrenceDaily,
			RecurrenceTime: &recTime,
			Timezone:       "Asia/Baghdad",
		}
		// 14:00 is after 08:00 today
		if !svc.IsBannerActiveNow(b, now) {
			t.Errorf("Expected banner to be active after recurrence time")
		}

		// 06:00 is before 08:00 today
		earlyNow := time.Date(2026, 8, 4, 6, 0, 0, 0, loc)
		if svc.IsBannerActiveNow(b, earlyNow) {
			t.Errorf("Expected banner to be inactive before recurrence time")
		}
	})
}

func TestMatchesTargeting(t *testing.T) {
	svc := service.NewBannerService(nil, nil, 300)

	t.Run("Matching version 1 role targeting", func(t *testing.T) {
		b := &domain.Banner{
			TargetingRules: map[string]interface{}{
				"version": 1,
				"roles":   []interface{}{"customer", "merchant"},
			},
		}

		if !svc.MatchesTargeting(b, "customer", 0) {
			t.Errorf("Expected role 'customer' to match targeting rules")
		}
		if !svc.MatchesTargeting(b, "merchant", 0) {
			t.Errorf("Expected role 'merchant' to match targeting rules")
		}
		if svc.MatchesTargeting(b, "admin", 0) {
			t.Errorf("Expected role 'admin' not to match customer/merchant targeting rules")
		}
	})

	t.Run("Matching governorate targeting", func(t *testing.T) {
		b := &domain.Banner{
			TargetingRules: map[string]interface{}{
				"version":         1,
				"governorate_ids": []interface{}{float64(1), float64(2)},
			},
		}

		if !svc.MatchesTargeting(b, "customer", 1) {
			t.Errorf("Expected governorate 1 to match targeting rules")
		}
		if svc.MatchesTargeting(b, "customer", 5) {
			t.Errorf("Expected governorate 5 not to match targeting rules")
		}
	})
}

func TestMerchantPermissionCheckValidation(t *testing.T) {
	svc := service.NewBannerService(nil, nil, 300)
	ctx := context.Background()

	t.Run("Create banner missing image_url returns error", func(t *testing.T) {
		_, err := svc.CreateBanner(ctx, uuid.New(), string(domain.RoleAdmin), domain.CreateBannerRequest{
			ImageURL:   "",
			Placements: []string{"home"},
		})
		if err == nil {
			t.Errorf("Expected error for empty image_url")
		}
	})

	t.Run("Create banner priority out of range returns error", func(t *testing.T) {
		_, err := svc.CreateBanner(ctx, uuid.New(), string(domain.RoleAdmin), domain.CreateBannerRequest{
			ImageURL:   "https://example.com/banner.jpg",
			Priority:   150,
			Placements: []string{"home"},
		})
		if err == nil {
			t.Errorf("Expected error for priority 150")
		}
	})
}
