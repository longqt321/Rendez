//go:build integration

package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"rendez-backend/internal/auth"
	"rendez-backend/internal/catalog"
	"strings"
	"testing"
)

func TestLocalJourney(t *testing.T) {
	pool := isolatedPool(t)
	t.Chdir("../..")
	ctx := context.Background()
	if err := migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	admin, err := auth.SeedDemoAdmin(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if err := catalog.Seed(ctx, pool, admin); err != nil {
		t.Fatal(err)
	}
	if err := catalog.Seed(ctx, pool, admin); err != nil {
		t.Fatal(err)
	}
	handler := routes(ctx, pool, "development")
	call := func(method, path, body, token string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(method, path, strings.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, req)
		return response
	}
	registration := `{"email":"journey@example.com","password":"JourneyPass123!","display_name":"Journey User"}`
	account := call("POST", "/v1/auth/register", registration, "")
	if account.Code != 201 {
		t.Fatalf("register %d: %s", account.Code, account.Body)
	}
	var result struct{ Token string }
	if err := json.Unmarshal(account.Body.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if call("POST", "/v1/auth/register", registration, "").Code != 409 {
		t.Fatal("duplicate email accepted")
	}
	if call("POST", "/v1/auth/login", `{"email":"journey@example.com","password":"WrongPass123!"}`, "").Code != 401 {
		t.Fatal("wrong password accepted")
	}
	id := "00000000-0000-4000-8000-000000000101"
	if call("PUT", "/v1/favorites/"+id, "", "").Code != 401 {
		t.Fatal("anonymous favorite accepted")
	}
	if call("PUT", "/v1/favorites/"+id, "", result.Token).Code != 204 {
		t.Fatal("save failed")
	}
	if call("PUT", "/v1/favorites/"+id, "", result.Token).Code != 204 {
		t.Fatal("repeat save failed")
	}
	// New router/session simulates client reconnect; saved data must remain in PostgreSQL.
	login := call("POST", "/v1/auth/login", `{"email":"journey@example.com","password":"JourneyPass123!"}`, "")
	if login.Code != 200 {
		t.Fatal("login failed")
	}
	json.Unmarshal(login.Body.Bytes(), &result)
	handler = routes(ctx, pool, "development")
	favorites := call("GET", "/v1/favorites", "", result.Token)
	if favorites.Code != 200 || !strings.Contains(favorites.Body.String(), id) {
		t.Fatal("favorite did not persist")
	}
	var count int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM favorites`).Scan(&count); err != nil || count != 1 {
		t.Fatal("duplicate favorite")
	}
	var stored string
	if err := pool.QueryRow(ctx, `SELECT password_hash FROM users WHERE email='journey@example.com'`).Scan(&stored); err != nil || stored == "JourneyPass123!" {
		t.Fatal("password not hashed")
	}
	// Catalog API must reflect a database edit, not return a hardcoded fixture.
	if _, err := pool.Exec(ctx, `UPDATE menu_items SET price=39000 WHERE place_id=$1 AND name='Cà phê sữa'`, id); err != nil {
		t.Fatal(err)
	}
	detail := call("GET", "/v1/places/"+id, "", "")
	if detail.Code != 200 || !strings.Contains(detail.Body.String(), "39000") {
		t.Fatal("detail does not reflect database")
	}
	if _, err := pool.Exec(ctx, `UPDATE places SET publication_state='hidden' WHERE id=$1`, id); err != nil {
		t.Fatal(err)
	}
	if call("GET", "/v1/places/"+id, "", "").Code != 404 {
		t.Fatal("hidden place is public")
	}
	if call("DELETE", "/v1/auth/session", "", result.Token).Code != 204 {
		t.Fatal("logout failed")
	}
	if call("GET", "/v1/favorites", "", result.Token).Code != 401 {
		t.Fatal("revoked session accepted")
	}
	req := httptest.NewRequest(http.MethodOptions, "/v1/auth/login", nil)
	req.Header.Set("Origin", "http://localhost:7357")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	if response.Code != 204 || response.Header().Get("Access-Control-Allow-Origin") != "http://localhost:7357" {
		t.Fatal("local web CORS failed")
	}
}

func TestFlutterHTTPJourney(t *testing.T) {
	t.Setenv("UPLOAD_DIR", t.TempDir())
	if os.Getenv("RUN_FLUTTER_INTEGRATION") != "1" {
		t.Skip("run make integration-ui for Flutter against a real API")
	}
	pool := isolatedPool(t)
	t.Chdir("../..")
	ctx := context.Background()
	if err := migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	admin, err := auth.SeedDemoAdmin(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if err := catalog.Seed(ctx, pool, admin); err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(routes(ctx, pool, "development"))
	defer server.Close()
	// Flutter uses the actual app client/providers against this HTTP server and real PostgreSQL.
	cmd := exec.Command("flutter", "test", "--no-pub", "test/live_api_test.dart", "--dart-define=LIVE_API_TEST=true", "--dart-define=API_BASE_URL="+server.URL)
	cmd.Dir = filepath.Join("..", "mobile")
	cmd.Env = os.Environ()
	output, err := cmd.CombinedOutput()
	t.Log(string(output))
	if err != nil {
		t.Fatal(err)
	}
	var count int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE email LIKE 'flutter-%@example.com'`).Scan(&count); err != nil || count != 2 {
		t.Fatal("Flutter accounts were not stored in PostgreSQL")
	}
}
