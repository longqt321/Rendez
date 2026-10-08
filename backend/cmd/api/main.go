package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"rendez-backend/internal/auth"
	"rendez-backend/internal/catalog"
	"rendez-backend/internal/httpx"
)

const schemaVersion = 5

func main() {
	migrateOnly := flag.Bool("migrate", false, "apply Goose migrations and exit (run from backend/)")
	seedDemo := flag.Bool("seed-demo", false, "seed local database catalog and demonstration admin")
	seedDev := flag.Bool("seed-dev", false, "create development User/Admin fixtures (dev build only)")
	flag.Parse()
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, *migrateOnly, *seedDev, *seedDemo); err != nil {
		slog.Error("backend stopped", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, migrateOnly, seedDev, seedDemo bool) error {
	appEnv := os.Getenv("APP_ENV")
	switch appEnv {
	case "development", "test", "production":
	default:
		return errors.New("APP_ENV must be development, test or production")
	}
	if err := auth.ValidateBuild(appEnv); err != nil {
		return err
	}
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		return errors.New("DATABASE_URL is required")
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		// Connection parsing errors can contain credentials. Never log raw input/error.
		return errors.New("invalid DATABASE_URL; check PostgreSQL connection settings")
	}
	cfg.MaxConns = 4
	cfg.ConnConfig.ConnectTimeout = 2 * time.Second
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return errors.New("could not initialize PostgreSQL pool")
	}
	defer pool.Close()

	startup, cancel := context.WithTimeout(ctx, 5*time.Second)
	err = pool.Ping(startup)
	cancel()
	if err != nil {
		return errors.New("PostgreSQL unavailable; check the database service and DATABASE_URL")
	}
	slog.Info("PostgreSQL connected")

	if migrateOnly {
		return migrate(ctx, pool)
	}
	if seedDemo {
		if appEnv != "development" {
			return errors.New("demo seed requires APP_ENV=development")
		}
		if err := ready(ctx, pool); err != nil {
			return err
		}
		id, err := auth.SeedDemoAdmin(ctx, pool)
		if err != nil {
			return err
		}
		return catalog.Seed(ctx, pool, id)
	}
	if seedDev {
		if err := ready(ctx, pool); err != nil {
			return errors.New("database is not ready; run migrations before seeding")
		}
		return auth.SeedDev(ctx, pool, appEnv)
	}
	if err := ready(ctx, pool); err != nil {
		return errors.New("database is not ready; check connectivity and run migrations for this binary")
	}
	addr := os.Getenv("HTTP_ADDR")
	if addr == "" {
		addr = "127.0.0.1:8080"
	}
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("cannot listen on HTTP_ADDR: %w", err)
	}
	server := &http.Server{
		Handler:           routes(ctx, pool, appEnv),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       60 * time.Second,
		WriteTimeout:      60 * time.Second,
		IdleTimeout:       60 * time.Second,
		ErrorLog:          slog.NewLogLogger(slog.Default().Handler(), slog.LevelError),
	}
	finished := make(chan error, 1)
	go func() { finished <- server.Serve(listener) }()
	slog.Info("HTTP server started", "address", listener.Addr().String())

	select {
	case err := <-finished:
		return fmt.Errorf("HTTP server failed: %w", err)
	case <-ctx.Done():
		slog.Info("shutting down")
	}
	shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdown); err != nil {
		_ = server.Close()
		return fmt.Errorf("HTTP shutdown failed: %w", err)
	}
	if err := <-finished; !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("HTTP server failed: %w", err)
	}
	slog.Info("HTTP server stopped")
	return nil
}

func migrate(ctx context.Context, pool *pgxpool.Pool) error {
	// Goose uses database/sql through pgx; readiness uses pgxpool directly.
	db := stdlib.OpenDBFromPool(pool)
	defer db.Close()
	provider, err := goose.NewProvider(goose.DialectPostgres, db, os.DirFS("migrations/core"))
	if err != nil {
		return errors.New("cannot load Goose migrations; run from backend/ and check migrations/core")
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	if _, err := provider.Up(ctx); err != nil {
		return errors.New("Goose migration failed; check database connectivity, permissions and migration SQL")
	}
	slog.Info("Goose migrations applied")
	return nil
}

func ready(ctx context.Context, pool *pgxpool.Pool) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	var version int64
	if err := pool.QueryRow(ctx, "SELECT COALESCE(MAX(version_id), 0) FROM goose_db_version WHERE is_applied").Scan(&version); err != nil {
		return err
	}
	if version != schemaVersion {
		return errors.New("incompatible database schema")
	}
	return nil
}

func routes(ctx context.Context, pool *pgxpool.Pool, appEnv string) http.Handler {
	r := chi.NewRouter()
	r.Get("/health/live", func(w http.ResponseWriter, r *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	r.Get("/health/ready", func(w http.ResponseWriter, r *http.Request) {
		if ctx.Err() != nil || ready(r.Context(), pool) != nil {
			httpx.Error(w, http.StatusServiceUnavailable, "database_unavailable", "Máy chủ chưa sẵn sàng. Hãy thử lại.", true)
			return
		}
		httpx.JSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
	auth.Register(r, pool, appEnv)
	catalog.Register(r, pool)
	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		httpx.Error(w, http.StatusNotFound, "not_found", "Resource not found", false)
	})
	r.MethodNotAllowed(func(w http.ResponseWriter, r *http.Request) {
		httpx.Error(w, http.StatusMethodNotAllowed, "method_not_allowed", "Method not allowed", false)
	})
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		origin := req.Header.Get("Origin")
		if appEnv == "development" && origin != "" {
			u, err := url.Parse(origin)
			if err == nil && (u.Scheme == "http" || u.Scheme == "https") && (u.Hostname() == "localhost" || u.Hostname() == "127.0.0.1") {
				w.Header().Set("Access-Control-Allow-Origin", origin)
				w.Header().Set("Vary", "Origin")
				w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
				if req.Method == http.MethodOptions {
					w.WriteHeader(http.StatusNoContent)
					return
				}
			}
		}
		r.ServeHTTP(w, req)
	})
}
