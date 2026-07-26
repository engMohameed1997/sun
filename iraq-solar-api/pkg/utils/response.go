package utils

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// APIResponse — النمط الموحد لجميع استجابات الـ API
type APIResponse struct {
	Success   bool        `json:"success"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	ErrorCode string      `json:"error_code,omitempty"`
	Timestamp string      `json:"timestamp"`
}

// SuccessResponse — إرجاع استجابة نجاح موحدة
func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, APIResponse{
		Success:   true,
		Message:   message,
		Data:      data,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	})
}

// ErrorResponse — إرجاع خطأ موحد للعميل مع إخفاء تفاصيل النظام والبرمجة (Requirement 4)
func ErrorResponse(c *gin.Context, statusCode int, clientMessage string, errorCode string, internalErr error) {
	// تسجيل الخطأ الداخلي الحقيقي في السيرفر لأغراض الـ Debug دون إظهاره للمستخدم
	if internalErr != nil {
		slog.Error("Internal Error Encountered",
			"path", c.Request.URL.Path,
			"method", c.Request.Method,
			"client_ip", c.ClientIP(),
			"error_code", errorCode,
			"internal_err", internalErr.Error(),
		)
	}

	// إرجاع الرسالة الآمنة الموحدة للزبون فقط
	c.JSON(statusCode, APIResponse{
		Success:   false,
		Message:   clientMessage,
		ErrorCode: errorCode,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	})
}

// InternalServerError — خطأ سيرفر عام آمن لا يكشف التفاصيل الداخلية
func InternalServerError(c *gin.Context, internalErr error) {
	ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ غير متوقع في النظام، يرجى المحاولة لاحقاً", "INTERNAL_SERVER_ERROR", internalErr)
}

// BadRequestError — خطأ في مدخلات المستخدم
func BadRequestError(c *gin.Context, message string, internalErr error) {
	if message == "" {
		message = "المدخلات غير صالحة أو غير مكتملة"
	}
	ErrorResponse(c, http.StatusBadRequest, message, "INVALID_INPUT", internalErr)
}

// UnauthorizedError — خطأ صلاحيات التوثيق
func UnauthorizedError(c *gin.Context, message string) {
	if message == "" {
		message = "غير مصرح، يرجى تسجيل الدخول وإرسال التوكنات المطلوبة"
	}
	ErrorResponse(c, http.StatusUnauthorized, message, "UNAUTHORIZED", nil)
}

// ForbiddenError — خطأ الوصول غير المسموح
func ForbiddenError(c *gin.Context, message string) {
	if message == "" {
		message = "ليس لديك الصلاحية لتنفيذ هذا الإجراء"
	}
	ErrorResponse(c, http.StatusForbidden, message, "FORBIDDEN", nil)
}
