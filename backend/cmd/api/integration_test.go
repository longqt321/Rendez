//go:build integration

package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func isolatedPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Fatal("TEST_DATABASE_URL is required for integration tests")
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		t.Fatal("invalid TEST_DATABASE_URL")
	}
	if cfg.ConnConfig.Host != "127.0.0.1" && cfg.ConnConfig.Host != "localhost" {
		t.Fatal("integration tests require loopback PostgreSQL")
	}
	if cfg.ConnConfig.Database != "rendez_test" {
		t.Fatal("integration tests require the disposable rendez_test database")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	admin, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		t.Fatal("cannot open local test connection")
	}
	t.Cleanup(admin.Close)
	var suffix [4]byte
	if _, err := rand.Read(suffix[:]); err != nil {
		t.Fatal(err)
	}
	name := "rendez_test_" + hex.EncodeToString(suffix[:])
	if _, err := admin.Exec(ctx, "CREATE DATABASE "+name); err != nil {
		t.Fatal("cannot create isolated test database:", err)
	}
	t.Cleanup(func() {
		cleanup, done := context.WithTimeout(context.Background(), 5*time.Second)
		defer done()
		if _, err := admin.Exec(cleanup, "DROP DATABASE "+name); err != nil {
			t.Errorf("cannot remove isolated test database: %v", err)
		}
	})
	isolated := cfg.Copy()
	isolated.ConnConfig.Database = name
	pool, err := pgxpool.NewWithConfig(ctx, isolated)
	if err != nil {
		t.Fatal("cannot connect to isolated test database")
	}
	t.Cleanup(pool.Close)
	if err := pool.Ping(ctx); err != nil {
		t.Fatal("isolated PostgreSQL unavailable")
	}
	return pool
}

func TestM0Postgres(t *testing.T) {
	pool := isolatedPool(t)
	t.Chdir("../..") // go test runs in cmd/api; migrations live at backend/migrations/core.
	ctx := context.Background()
	if err := migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if err := migrate(ctx, pool); err != nil {
		t.Fatal("migration is not repeatable:", err)
	}
	if err := ready(ctx, pool); err != nil {
		t.Fatal("migrated database should be ready:", err)
	}
	r := routes(ctx, pool, "test")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/health/ready", nil))
	if w.Code != http.StatusOK || !strings.Contains(w.Body.String(), "ready") {
		t.Fatalf("ready response: %d %s", w.Code, w.Body.String())
	}
	pool.Close()
	w = httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/health/ready", nil))
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("closed PostgreSQL pool reported ready: %d", w.Code)
	}
}
