package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestM0Live(t *testing.T) {
	pool, err := pgxpool.New(context.Background(), "postgres://localhost/unused?sslmode=disable")
	if err != nil {
		t.Fatal(err)
	}
	pool.Close()
	r := routes(context.Background(), pool, "test")
	live := httptest.NewRecorder()
	r.ServeHTTP(live, httptest.NewRequest(http.MethodGet, "/health/live", nil))
	if live.Code != http.StatusOK || live.Body.String() != "{\"status\":\"ok\"}\n" {
		t.Fatalf("liveness with unavailable database: %d %s", live.Code, live.Body.String())
	}
	readyResponse := httptest.NewRecorder()
	r.ServeHTTP(readyResponse, httptest.NewRequest(http.MethodGet, "/health/ready", nil))
	if readyResponse.Code != http.StatusServiceUnavailable {
		t.Fatalf("readiness with unavailable database: %d %s", readyResponse.Code, readyResponse.Body.String())
	}
}
