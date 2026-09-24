package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"rendez-backend/config"
	"rendez-backend/internal/platform/db"
	"rendez-backend/pkg/middleware"
	"rendez-backend/pkg/response"
)

func main() {
	cfg := config.Load()

	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	database, err := db.NewConnection(cfg)
	if err != nil {
		log.Fatalf("Fatal: Database initialization failed: %v", err)
	}

	router := gin.New()
	router.Use(middleware.LoggerMiddleware())
	router.Use(middleware.RecoverMiddleware())

	// Health check endpoint (T0.5)
	router.GET("/health", healthCheckHandler(database))

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	go func() {
		log.Printf("Rendez API Server is listening on port %s (env: %s)...", cfg.Port, cfg.Env)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Server Listen error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exiting successfully")
}

func healthCheckHandler(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			response.ErrorWithStatus(c, http.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "Database connection is down")
			return
		}

		response.Success(c, http.StatusOK, gin.H{
			"status": "ok",
			"db":     "ok",
			"time":   time.Now().Format(time.RFC3339),
		})
	}
}
