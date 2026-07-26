package utils

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"image"
	"image/gif"
	"image/jpeg"
	"image/png"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

// ProcessedImage — نتيجة معالجة الصورة الآمنة
type ProcessedImage struct {
	SecureFileName string
	RelativePath   string
	Format         string
	Width          int
	Height         int
	SizeBytes      int64
}

// ProcessAndSaveImage — معالجة وتنظيف وتجريد الصورة من الميتا داتا وتوليد اسم عشوائي (Requirement 3)
func ProcessAndSaveImage(fileHeader *multipart.FileHeader, uploadDir string) (*ProcessedImage, error) {
	// 1. فتح الملف المرفوع
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	// 2. التحقق من حجم الملف (حد أقصى 10 ميجابايت)
	if fileHeader.Size > 10*1024*1024 {
		return nil, errors.New("حجم الصورة يتجاوز الحد المسموح به (10 ميجابايت)")
	}

	// 3. قراءة الـ Header للتحقق من Magic Bytes (MIME Type الحقيقي)
	headerBytes := make([]byte, 512)
	n, err := src.Read(headerBytes)
	if err != nil && err != io.EOF {
		return nil, errors.New("فشل في قراءة محتوى الصورة")
	}
	src.Seek(0, io.SeekStart) // إعادة مؤشر القراءة للبداية

	mimeType := http.DetectContentType(headerBytes[:n])
	allowedTypes := map[string]string{
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/gif":  ".gif",
	}

	ext, isAllowed := allowedTypes[mimeType]
	if !isAllowed {
		return nil, errors.New("صيغة الملف غير مدعومة، يرجى رفع صورة بصيغة (JPG, PNG, GIF) فقط")
	}

	// 4. قراءة البكسلات وتجريد الصورة تماماً من بيانات EXIF والميتاداتا بواسطة re-decoding
	img, format, err := image.Decode(src)
	if err != nil {
		return nil, errors.New("الملف المرفوع مقتطع أو تالف ولا يمكن معالجته كصورة")
	}

	// 5. توليد اسم عشوائي غير قابل للتكرار إطلاقاً باستخدام UUID + Random Cryptographic Bytes (Requirement 3)
	randomBytes := make([]byte, 8)
	if _, err := rand.Read(randomBytes); err != nil {
		return nil, fmt.Errorf("failed to generate random filename: %w", err)
	}
	randomPrefix := hex.EncodeToString(randomBytes)
	secureFileName := fmt.Sprintf("%s_%s%s", randomPrefix, uuid.New().String(), ext)

	// 6. التأكد من وجود مجلد الحفظ
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	dstPath := filepath.Join(uploadDir, secureFileName)
	out, err := os.Create(dstPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create target image file: %w", err)
	}
	defer out.Close()

	// 7. إعادة كتابة البكسلات بترميز نظيف خالي من أي سكربتات أو الميتاداتا الأصلية
	switch strings.ToLower(format) {
	case "jpeg", "jpg":
		err = jpeg.Encode(out, img, &jpeg.Options{Quality: 85})
	case "png":
		err = png.Encode(out, img)
	case "gif":
		err = gif.Encode(out, img, nil)
	default:
		err = jpeg.Encode(out, img, &jpeg.Options{Quality: 85})
	}

	if err != nil {
		return nil, fmt.Errorf("failed to re-encode clean image: %w", err)
	}

	fileInfo, err := out.Stat()
	sizeBytes := int64(0)
	if err == nil {
		sizeBytes = fileInfo.Size()
	}

	bounds := img.Bounds()
	return &ProcessedImage{
		SecureFileName: secureFileName,
		RelativePath:   filepath.Join("uploads", secureFileName),
		Format:         format,
		Width:          bounds.Dx(),
		Height:         bounds.Dy(),
		SizeBytes:      sizeBytes,
	}, nil
}
