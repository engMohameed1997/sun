package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port           string
	DatabaseURL    string
	JWTSecret      string
	Environment    string
	MinIOEndpoint       string
	MinIOPublicEndpoint string
	MinIOAccessKey      string
	MinIOSecretKey      string
	MinIOBucket         string
	MinIOUseSSL         bool
	RedisURL            string
	RedisBannerCacheTTL int
}

func Load() *Config {
	return &Config{
		Port:                getEnv("PORT", "8080"),
		DatabaseURL:         getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/iraq_solar_db?sslmode=disable"),
		JWTSecret:           getEnv("JWT_SECRET", "super-secret-iraq-solar-jwt-key-2026"),
		Environment:         getEnv("ENVIRONMENT", "development"),
		MinIOEndpoint:       getEnv("MINIO_ENDPOINT", "localhost:9000"),
		MinIOPublicEndpoint: getEnv("MINIO_PUBLIC_ENDPOINT", ""),
		MinIOAccessKey:      getEnv("MINIO_ACCESS_KEY", "iraqsolar"),
		MinIOSecretKey:      getEnv("MINIO_SECRET_KEY", "iraqsolar_minio_2026"),
		MinIOBucket:         getEnv("MINIO_BUCKET", "iraqsolar"),
		MinIOUseSSL:         getEnv("MINIO_USE_SSL", "false") == "true",
		RedisURL:            getEnv("REDIS_URL", "localhost:6379"),
		RedisBannerCacheTTL: getEnvAsInt("REDIS_BANNER_CACHE_TTL_SECONDS", 300),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value
	}
	return fallback
}

func getEnvAsInt(key string, fallback int) int {
	strValue := getEnv(key, "")
	if value, err := strconv.Atoi(strValue); err == nil {
		return value
	}
	return fallback
}
