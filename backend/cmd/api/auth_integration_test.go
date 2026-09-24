//go:build integration && dev

package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"rendez-backend/internal/auth"
)

func TestM1Sessions(t *testing.T) {
	pool := isolatedPool(t)
	t.Chdir("../..")
	ctx := context.Background()
	if err := migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if err := auth.SeedDev(ctx, pool, "development"); err != nil {
		t.Fatal(err)
	}
	handler := routes(ctx, pool, "development")
	login := func(fixture string) (string, string) {
		t.Helper()
		response := httptest.NewRecorder()
		request := httptest.NewRequest(http.MethodPost, "/dev/login", strings.NewReader("{\"fixture\":\""+fixture+"\"}"))
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusCreated {
			t.Fatalf("%s login status %d: %s", fixture, response.Code, response.Body.String())
		}
		var result struct {
			Token string
			User  struct {
				ID   string
				Role string
			}
		}
		if err := json.Unmarshal(response.Body.Bytes(), &result); err != nil {
			t.Fatal(err)
		}
		if result.Token == "" || result.User.Role != fixture {
			t.Fatal("development login returned wrong identity")
		}
		return result.Token, result.User.ID
	}
	call := func(method, path, token string) *httptest.ResponseRecorder {
		t.Helper()
		request := httptest.NewRequest(method, path, nil)
		request.Header.Set("Authorization", "Bearer "+token)
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		return response
	}
	userToken, userID := login("user")
	adminToken, adminID := login("admin")
	if call(http.MethodGet, "/v1/me", userToken).Code != http.StatusOK {
		t.Fatal("user session should be active")
	}
	if call(http.MethodGet, "/v1/me", adminToken).Code != http.StatusOK {
		t.Fatal("admin session should be active")
	}
	userReq := httptest.NewRequest(http.MethodPost, "/v1/admin/check", nil)
	userReq.Header.Set("Authorization", "Bearer "+userToken)
	denied := httptest.NewRecorder()
	if _, ok := auth.RequireAdmin(denied, userReq, pool); ok || denied.Code != http.StatusForbidden {
		t.Fatal("ordinary user passed Admin guard")
	}
	if _, err := pool.Exec(ctx, "UPDATE users SET role = 'user' WHERE id = $1", adminID); err != nil {
		t.Fatal(err)
	}
	adminReq := httptest.NewRequest(http.MethodPost, "/v1/admin/check", nil)
	adminReq.Header.Set("Authorization", "Bearer "+adminToken)
	denied = httptest.NewRecorder()
	if _, ok := auth.RequireAdmin(denied, adminReq, pool); ok || denied.Code != http.StatusForbidden {
		t.Fatal("old Admin session kept a stale role")
	}
	if call(http.MethodDelete, "/v1/auth/session", userToken).Code != http.StatusNoContent {
		t.Fatal("logout failed")
	}
	if call(http.MethodGet, "/v1/me", userToken).Code != http.StatusUnauthorized {
		t.Fatal("revoked session was accepted")
	}
	if _, err := pool.Exec(ctx, "UPDATE users SET active = false WHERE id = $1", userID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "UPDATE users SET role = 'admin' WHERE id = $1", adminID); err != nil {
		t.Fatal(err)
	}
	secondToken, _ := login("admin")
	if _, err := pool.Exec(ctx, "UPDATE sessions SET created_at = now() - interval '8 days', expires_at = now() - interval '1 second' WHERE user_id = $1", adminID); err != nil {
		t.Fatal(err)
	}
	if call(http.MethodGet, "/v1/me", secondToken).Code != http.StatusUnauthorized {
		t.Fatal("expired session was accepted")
	}
}
