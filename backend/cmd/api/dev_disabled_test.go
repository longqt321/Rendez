//go:build !dev

package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestNormalBuildHasNoDevLogin(t *testing.T) {
	pool, err := pgxpool.New(context.Background(), "postgres://localhost/unused?sslmode=disable")
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	request := httptest.NewRequest(http.MethodPost, "/dev/login", nil)
	response := httptest.NewRecorder()
	routes(context.Background(), pool, "development").ServeHTTP(response, request)
	if response.Code != http.StatusNotFound {
		t.Fatalf("normal build exposed development login: %d", response.Code)
	}
}
