package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Port            string
	Env             string
	DBHost          string
	DBPort          string
	DBUser          string
	DBPassword      string
	DBName          string
	DBSSLMode       string
	JWTSecret       string
	JWTAccessTTL    time.Duration
	JWTRefreshTTL   time.Duration
	OCRServiceURL   string
	MapServiceURL   string
	MapServiceKey   string
	UploadMaxSizeMB int64
	UploadDir       string
}

func Load() *Config {
	_ = godotenv.Load() // Tự động load .env nếu có, bỏ qua nếu chạy môi trường container/prod

	cfg := &Config{
		Port:          getEnvOrDefault("PORT", "8080"),
		Env:           getEnvOrDefault("ENV", "development"),
		DBHost:        mustGetEnv("DB_HOST"),
		DBPort:        getEnvOrDefault("DB_PORT", "5432"),
		DBUser:        mustGetEnv("DB_USER"),
		DBPassword:    mustGetEnv("DB_PASSWORD"),
		DBName:        mustGetEnv("DB_NAME"),
		DBSSLMode:     getEnvOrDefault("DB_SSLMODE", "disable"),
		JWTSecret:     mustGetEnv("JWT_SECRET"),
		OCRServiceURL: getEnvOrDefault("OCR_SERVICE_URL", "http://localhost:8000"),
		MapServiceURL: getEnvOrDefault("MAP_SERVICE_URL", "http://localhost:8001"),
		MapServiceKey: os.Getenv("MAP_SERVICE_API_KEY"),
		UploadDir:     getEnvOrDefault("UPLOAD_DIR", "./uploads"),
	}

	accessTTLStr := getEnvOrDefault("JWT_ACCESS_TTL", "30m")
	accessTTL, err := time.ParseDuration(accessTTLStr)
	if err != nil {
		panic(fmt.Sprintf("Invalid JWT_ACCESS_TTL format: %v", err))
	}
	cfg.JWTAccessTTL = accessTTL

	refreshTTLStr := getEnvOrDefault("JWT_REFRESH_TTL", "336h") // 14 days
	refreshTTL, err := time.ParseDuration(refreshTTLStr)
	if err != nil {
		panic(fmt.Sprintf("Invalid JWT_REFRESH_TTL format: %v", err))
	}
	cfg.JWTRefreshTTL = refreshTTL

	maxSizeStr := getEnvOrDefault("UPLOAD_MAX_SIZE_MB", "10")
	maxSize, err := strconv.ParseInt(maxSizeStr, 10, 64)
	if err != nil {
		panic(fmt.Sprintf("Invalid UPLOAD_MAX_SIZE_MB format: %v", err))
	}
	cfg.UploadMaxSizeMB = maxSize

	return cfg
}

func mustGetEnv(key string) string {
	val := os.Getenv(key)
	if val == "" {
		panic(fmt.Sprintf("Missing required environment variable: %s", key))
	}
	return val
}

func getEnvOrDefault(key, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	return val
}
