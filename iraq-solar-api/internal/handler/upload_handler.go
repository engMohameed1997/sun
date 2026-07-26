package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
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
		c.JSON(http.StatusBadRequest, gin.H{"error": "فشل في قراءة الملف"})
		return
	}
	defer file.Close()

	url, err := h.minioService.UploadImage(c.Request.Context(), file, header)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "فشل في رفع الملف"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": url})
}
