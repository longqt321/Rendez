package db

import (
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"rendez-backend/config"
)

func NewConnection(cfg *config.Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=Asia/Ho_Chi_Minh",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode,
	)

	gormLogger := logger.Default.LogMode(logger.Warn)
	if cfg.Env == "development" {
		gormLogger = logger.Default.LogMode(logger.Info)
	}

	var db *gorm.DB
	var err error

	maxRetries := 5
	backoff := 2 * time.Second

	for i := 1; i <= maxRetries; i++ {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
			Logger: gormLogger,
		})
		if err == nil {
			sqlDB, sqlErr := db.DB()
			if sqlErr == nil {
				if pingErr := sqlDB.Ping(); pingErr == nil {
					sqlDB.SetMaxOpenConns(25)
					sqlDB.SetMaxIdleConns(10)
					sqlDB.SetConnMaxLifetime(15 * time.Minute)
					log.Println("Database connection established successfully")
					return db, nil
				}
			}
		}

		log.Printf("Attempt %d/%d: Failed to connect to DB, retrying in %v...", i, maxRetries, backoff)
		time.Sleep(backoff)
		backoff *= 2
	}

	return nil, fmt.Errorf("could not connect to database after %d retries: %w", maxRetries, err)
}
