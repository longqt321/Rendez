//go:build integration

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"mime/multipart"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"rendez-backend/internal/auth"
	"rendez-backend/internal/catalog"
)

func TestContributionJourney(t *testing.T) {
	pool := isolatedPool(t)
	t.Chdir("../..")
	ctx := context.Background()
	t.Setenv("UPLOAD_DIR", t.TempDir())
	if err := migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	adminID, err := auth.SeedDemoAdmin(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if err = catalog.Seed(ctx, pool, adminID); err != nil {
		t.Fatal(err)
	}
	handler := routes(ctx, pool, "test")
	call := func(method, path, body, token string) *httptest.ResponseRecorder {
		r := httptest.NewRequest(method, path, strings.NewReader(body))
		r.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r)
		return w
	}
	token := func(path, body string) string {
		w := call("POST", path, body, "")
		if w.Code != 200 && w.Code != 201 {
			t.Fatalf("auth %d %s", w.Code, w.Body)
		}
		var v struct{ Token string }
		json.Unmarshal(w.Body.Bytes(), &v)
		return v.Token
	}
	user := token("/v1/auth/register", `{"email":"contributor@example.com","password":"TestPass123!","display_name":"Contributor"}`)
	other := token("/v1/auth/register", `{"email":"other@example.com","password":"TestPass123!","display_name":"Other"}`)
	admin := token("/v1/auth/login", `{"email":"longqt321@rendez.local","password":"123123123"}`)
	placeID := "00000000-0000-4000-8000-000000000101"
	if call("GET", "/v1/admin/places", "", user).Code != 403 {
		t.Fatal("User accessed Admin")
	}
	created := call("POST", "/v1/admin/places", `{"name":"Managed Place","address":"Address","city_code":"danang","category_code":"cafe","publication_state":"published"}`, admin)
	if created.Code != 201 {
		t.Fatalf("admin create %d %s", created.Code, created.Body)
	}
	var managed struct{ ID string }
	json.Unmarshal(created.Body.Bytes(), &managed)
	if call("PUT", "/v1/admin/places/"+managed.ID, `{"name":"Edited Place","address":"Address","city_code":"danang","category_code":"cafe","publication_state":"hidden"}`, admin).Code != 200 {
		t.Fatal("admin edit")
	}
	if call("GET", "/v1/places/"+managed.ID, "", "").Code != 404 {
		t.Fatal("hidden public")
	}
	if call("DELETE", "/v1/admin/places/"+managed.ID, "", admin).Code != 204 {
		t.Fatal("soft delete")
	}
	raw, err := os.ReadFile("internal/catalog/testdata/menu.png")
	if err != nil {
		t.Fatal(err)
	}
	upload := func(kind string, data []byte, newPlace bool, count int) *httptest.ResponseRecorder {
		var body bytes.Buffer
		m := multipart.NewWriter(&body)
		m.WriteField("type", kind)
		m.WriteField("captured_at", "2024-01-15T00:00:00Z")
		if newPlace {
			m.WriteField("place_name", "Community Draft")
			m.WriteField("address", "Community Address")
			m.WriteField("city_code", "danang")
			m.WriteField("category_code", "cafe")
		} else {
			m.WriteField("place_id", placeID)
		}
		for i := 0; i < count; i++ {
			f, _ := m.CreateFormFile("images", "menu.png")
			f.Write(data)
		}
		m.Close()
		req := httptest.NewRequest("POST", "/v1/contributions", &body)
		req.Header.Set("Content-Type", m.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+user)
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, req)
		return w
	}
	if upload("menu_photo", []byte("bad"), false, 1).Code != 422 {
		t.Fatal("bad image accepted")
	}
	if upload("menu_photo", raw, false, 6).Code != 422 {
		t.Fatal("six images accepted")
	}
	entries, _ := os.ReadDir(os.Getenv("UPLOAD_DIR"))
	if len(entries) != 0 {
		t.Fatal("failed upload left files")
	}
	uploaded := upload("menu_photo", raw, true, 1)
	if uploaded.Code != 201 {
		t.Fatalf("upload %d %s", uploaded.Code, uploaded.Body)
	}
	var contribution struct{ ID string }
	json.Unmarshal(uploaded.Body.Bytes(), &contribution)
	detail := call("GET", "/v1/contributions/"+contribution.ID, "", user)
	if detail.Code != 200 {
		t.Fatal("owner cannot see contribution")
	}
	var data struct {
		PlaceID  string `json:"place_id"`
		OCRText  string `json:"ocr_text"`
		OCRError string `json:"ocr_error"`
		Images   []struct {
			ID  string
			URL string
		}
		Draft []struct {
			Name  string
			Price int64
		} `json:"draft_items"`
	}
	json.Unmarshal(detail.Body.Bytes(), &data)
	if data.OCRError != "" || !strings.Contains(data.OCRText, "Coffee") || len(data.Draft) == 0 {
		t.Fatalf("real OCR failed: %s", detail.Body)
	}
	if call("GET", "/v1/contributions/"+contribution.ID, "", other).Code != 404 {
		t.Fatal("other user accessed private contribution")
	}
	if call("GET", data.Images[0].URL, "", other).Code != 404 {
		t.Fatal("other user accessed private image")
	}
	publicImage := "/v1/menu-images/" + data.Images[0].ID
	if call("GET", publicImage, "", "").Code != 404 {
		t.Fatal("pending image public")
	}
	if call("GET", "/v1/places/"+data.PlaceID, "", "").Code != 404 {
		t.Fatal("draft place public")
	}
	if call("DELETE", "/v1/admin/places/"+data.PlaceID, "", admin).Code != 409 {
		t.Fatal("deleted with pending contribution")
	}
	draft := `{"items":[{"name":"Coffee corrected","price":39000,"category":"Drinks"}]}`
	if call("PUT", "/v1/admin/contributions/"+contribution.ID+"/draft", draft, admin).Code != 204 {
		t.Fatal("draft save failed")
	}
	if !strings.Contains(call("GET", "/v1/contributions/"+contribution.ID, "", admin).Body.String(), "Coffee corrected") {
		t.Fatal("draft not persisted")
	}
	review := `{"decision":"approved","items":[{"name":"Coffee corrected","price":39000,"category":"Drinks"}]}`
	var wg sync.WaitGroup
	codes := make(chan int, 2)
	for i := 0; i < 2; i++ {
		wg.Go(func() {
			codes <- call("POST", "/v1/admin/contributions/"+contribution.ID+"/review", review, admin).Code
		})
	}
	wg.Wait()
	close(codes)
	successes, conflicts := 0, 0
	for code := range codes {
		if code == 204 {
			successes++
		} else if code == 409 {
			conflicts++
		} else {
			t.Fatalf("review status %d", code)
		}
	}
	if successes != 1 || conflicts != 1 {
		t.Fatal("concurrent approvals not serialized")
	}
	handler = routes(ctx, pool, "test")
	public := call("GET", "/v1/places/"+data.PlaceID, "", "")
	if public.Code != 200 || !strings.Contains(public.Body.String(), "39000") {
		t.Fatalf("approval not persisted %s", public.Body)
	}
	var evidence struct {
		Menu []struct {
			ObservedAt time.Time `json:"observed_at"`
			ReviewedAt time.Time `json:"reviewed_at"`
		} `json:"full_menu"`
	}
	if err := json.Unmarshal(public.Body.Bytes(), &evidence); err != nil || len(evidence.Menu) != 1 {
		t.Fatalf("missing menu provenance: %s", public.Body)
	}
	if evidence.Menu[0].ObservedAt.Format(time.RFC3339) != "2024-01-15T00:00:00Z" || !evidence.Menu[0].ReviewedAt.After(evidence.Menu[0].ObservedAt) {
		t.Fatal("review must not reset historical observation date")
	}
	if call("GET", publicImage, "", "").Code != 200 {
		t.Fatal("approved menu image unavailable")
	}
	rejected := upload("menu_photo", raw, false, 1)
	json.Unmarshal(rejected.Body.Bytes(), &contribution)
	if call("POST", "/v1/admin/contributions/"+contribution.ID+"/review", `{"decision":"rejected"}`, admin).Code != 422 {
		t.Fatal("reasonless rejection")
	}
	if call("POST", "/v1/admin/contributions/"+contribution.ID+"/review", `{"decision":"rejected","reason":"Wrong venue"}`, admin).Code != 204 {
		t.Fatal("rejection failed")
	}
	if call("POST", "/v1/admin/contributions/"+contribution.ID+"/review", review, admin).Code != 409 {
		t.Fatal("rejected contribution approved")
	}
	bill := upload("bill_photo", raw, false, 1)
	json.Unmarshal(bill.Body.Bytes(), &contribution)
	if call("POST", "/v1/admin/contributions/"+contribution.ID+"/review", `{"decision":"approved","bill_total":120000,"guests_count":2}`, admin).Code != 204 {
		t.Fatal("bill approval failed")
	}
	detail = call("GET", "/v1/contributions/"+contribution.ID, "", admin)
	json.Unmarshal(detail.Body.Bytes(), &data)
	if call("GET", "/v1/menu-images/"+data.Images[0].ID, "", "").Code != 404 {
		t.Fatal("bill original public")
	}
	if !strings.Contains(call("GET", "/v1/places/"+placeID, "", "").Body.String(), "120000") {
		t.Fatal("approved bill example missing")
	}
	// A real technical OCR failure remains retryable, not a rejection or fake success.
	t.Setenv("PATH", t.TempDir())
	failed := upload("menu_photo", raw, false, 1)
	if failed.Code != 201 {
		t.Fatal("OCR outage lost submission")
	}
	json.Unmarshal(failed.Body.Bytes(), &contribution)
	if !strings.Contains(call("GET", "/v1/contributions/"+contribution.ID, "", user).Body.String(), "OCR không khả dụng") {
		t.Fatal("OCR error not recorded")
	}
	if call("POST", "/v1/admin/contributions/"+contribution.ID+"/ocr", "", admin).Code != 503 {
		t.Fatal("OCR outage reported success")
	}
	entries, _ = os.ReadDir(os.Getenv("UPLOAD_DIR"))
	for _, entry := range entries {
		if filepath.Ext(entry.Name()) != ".png" {
			t.Fatal("unsafe storage name")
		}
	}
}
