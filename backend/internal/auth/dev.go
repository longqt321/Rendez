//go:build dev

package auth

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"rendez-backend/internal/httpx"
)

const (
	devUserID  = "00000000-0000-4000-8000-000000000001"
	devAdminID = "00000000-0000-4000-8000-000000000002"
)

func ValidateBuild(appEnv string) error {
	if appEnv != "development" {
		return errors.New("development build requires APP_ENV=development")
	}
	return nil
}

func SeedDev(ctx context.Context, pool *pgxpool.Pool, appEnv string) error {
	if err := ValidateBuild(appEnv); err != nil {
		return err
	}
	_, err := pool.Exec(ctx, `INSERT INTO users (id, display_name, role)
		VALUES ($1, 'Rendez User', 'user'), ($2, 'Rendez Admin', 'admin')
		ON CONFLICT (id) DO NOTHING`, devUserID, devAdminID)
	return err
}

func registerDev(r chi.Router, pool *pgxpool.Pool, appEnv string) {
	if appEnv != "development" {
		return
	}
	r.Post("/dev/login", func(w http.ResponseWriter, req *http.Request) {
		var input struct {
			Fixture string `json:"fixture"`
		}
		decoder := json.NewDecoder(http.MaxBytesReader(w, req.Body, 1024))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&input); err != nil {
			httpx.Error(w, http.StatusBadRequest, "invalid_json", "Invalid request body", false)
			return
		}
		if err := decoder.Decode(new(any)); err != io.EOF {
			httpx.Error(w, http.StatusBadRequest, "invalid_json", "Expected one JSON object", false)
			return
		}
		userID := devUserID
		if input.Fixture == "admin" {
			userID = devAdminID
		} else if input.Fixture != "user" {
			httpx.Error(w, http.StatusUnprocessableEntity, "invalid_fixture", "Unknown development fixture", false)
			return
		}
		token, expires, err := issue(req.Context(), pool, userID)
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.Error(w, http.StatusServiceUnavailable, "fixture_unavailable", "Run the development seed", true)
			return
		}
		if err != nil {
			httpx.Error(w, http.StatusServiceUnavailable, "database_unavailable", "Máy chủ chưa sẵn sàng. Hãy thử lại.", true)
			return
		}
		var name, role string
		if err := pool.QueryRow(req.Context(), `SELECT display_name, role FROM users WHERE id = $1`, userID).Scan(&name, &role); err != nil {
			httpx.Error(w, http.StatusServiceUnavailable, "database_unavailable", "Máy chủ chưa sẵn sàng. Hãy thử lại.", true)
			return
		}
		httpx.JSON(w, http.StatusCreated, map[string]any{
			"token": token, "token_type": "Bearer", "expires_at": expires,
			"user": map[string]string{"id": userID, "display_name": name, "role": role},
		})
	})
}
