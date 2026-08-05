package handler_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/handler"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/internal/service"
)

func TestBannerPublicEndpoints(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Create service & handler with nil DB/Cache for public test
	repo := repository.NewBannerRepository(nil)
	svc := service.NewBannerService(repo, nil, 300)
	h := handler.NewBannerHandler(svc)

	r := gin.New()
	v1 := r.Group("/api/v1")
	{
		v1.GET("/banners", h.GetActiveBanners)
		v1.POST("/banners/:id/track", h.TrackBannerEvent)
	}

	t.Run("GET /api/v1/banners returns empty active list on nil DB", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodGet, "/api/v1/banners?placement=home", nil)
		resp := httptest.NewRecorder()
		r.ServeHTTP(resp, req)

		if resp.Code != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.Code)
		}

		var body map[string]interface{}
		_ = json.Unmarshal(resp.Body.Bytes(), &body)
		if body["success"] != true {
			t.Errorf("Expected success = true")
		}
	})

	t.Run("POST /api/v1/banners/:id/track with invalid event_type returns 400", func(t *testing.T) {
		bannerID := uuid.New()
		payload := map[string]interface{}{
			"event_type": "invalid_event",
		}
		bodyBytes, _ := json.Marshal(payload)

		req, _ := http.NewRequest(http.MethodPost, "/api/v1/banners/"+bannerID.String()+"/track", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		resp := httptest.NewRecorder()
		r.ServeHTTP(resp, req)

		if resp.Code != http.StatusBadRequest {
			t.Errorf("Expected status 400 for invalid event type, got %d", resp.Code)
		}
	})

	t.Run("POST /api/v1/banners/:id/track with valid impression succeeds", func(t *testing.T) {
		bannerID := uuid.New()
		payload := map[string]interface{}{
			"event_type": "impression",
			"device_id":  "test-device-123",
		}
		bodyBytes, _ := json.Marshal(payload)

		req, _ := http.NewRequest(http.MethodPost, "/api/v1/banners/"+bannerID.String()+"/track", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		resp := httptest.NewRecorder()
		r.ServeHTTP(resp, req)

		if resp.Code != http.StatusOK {
			t.Errorf("Expected status 200 for valid event tracking, got %d", resp.Code)
		}
	})
}
