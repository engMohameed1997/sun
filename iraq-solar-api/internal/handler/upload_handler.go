package handler

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/service"
)

type UploadHandler struct {
	minioService *service.MinIOService
}

func NewUploadHandler(minioService *service.MinIOService) *UploadHandler {
	return &UploadHandler{minioService: minioService}
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		file, header, err = c.Request.FormFile("file")
	}
	if err != nil {
		file, header, err = c.Request.FormFile("logo")
	}
	if err != nil {
		file, header, err = c.Request.FormFile("icon")
	}
	if err != nil {
		file, header, err = c.Request.FormFile("cover")
	}
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "فشل في قراءة الملف. يرجى التأكد من اختيار ملف صورة صحيح"})
		return
	}
	defer file.Close()

	if h.minioService != nil {
		url, err := h.minioService.UploadImage(c.Request.Context(), file, header)
		if err == nil && url != "" {
			c.JSON(http.StatusOK, gin.H{"url": url, "data": gin.H{"url": url}})
			return
		}
		log.Printf("MinIO upload notice/fallback: %v", err)
	}

	// Local disk fallback
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "فشل في إنشاء مجلد المرفقات"})
		return
	}

	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := uuid.New().String() + ext
	dstPath := filepath.Join(uploadDir, filename)

	out, err := os.Create(dstPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "فشل في حفظ الملف على السيرفر"})
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "فشل في نسخ محتوى الملف"})
		return
	}

	scheme := "http"
	if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	host := c.Request.Host
	if host == "" {
		host = "localhost:8080"
	}

	url := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)
	c.JSON(http.StatusOK, gin.H{"url": url, "data": gin.H{"url": url}})
}
