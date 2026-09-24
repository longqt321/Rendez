package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"rendez-backend/internal/httpx"
)

var ErrUnauthenticated = errors.New("invalid or expired session")

type Principal struct {
	ID        string    `json:"id"`
	Name      string    `json:"display_name"`
	Role      string    `json:"role"`
	ExpiresAt time.Time `json:"session_expires_at"`
}

func Register(r chi.Router, pool *pgxpool.Pool, appEnv string) {
	r.Get("/v1/me", func(w http.ResponseWriter, req *http.Request) {
		principal, err := Current(req, pool)
		if err != nil {
			WriteAccessError(w, err)
			return
		}
		httpx.JSON(w, http.StatusOK, principal)
	})
	r.Delete("/v1/auth/session", func(w http.ResponseWriter, req *http.Request) {
		token := bearer(req)
		if token == "" {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		hash := sha256.Sum256([]byte(token))
		if _, err := pool.Exec(req.Context(), `UPDATE sessions SET revoked_at = now()
			WHERE token_hash = $1 AND revoked_at IS NULL`, hash[:]); err != nil {
			httpx.Error(w, http.StatusServiceUnavailable, "database_unavailable", "Database is not ready", true)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
	registerDev(r, pool, appEnv)
}

func Current(req *http.Request, pool *pgxpool.Pool) (Principal, error) {
	token := bearer(req)
	if token == "" {
		return Principal{}, ErrUnauthenticated
	}
	hash := sha256.Sum256([]byte(token))
	var principal Principal
	err := pool.QueryRow(req.Context(), `SELECT u.id::text, u.display_name, u.role, s.expires_at
		FROM sessions s JOIN users u ON u.id = s.user_id
		WHERE s.token_hash = $1 AND s.revoked_at IS NULL
		AND s.expires_at > now() AND u.active`, hash[:]).Scan(
		&principal.ID, &principal.Name, &principal.Role, &principal.ExpiresAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Principal{}, ErrUnauthenticated
	}
	return principal, err
}

func WriteAccessError(w http.ResponseWriter, err error) {
	if errors.Is(err, ErrUnauthenticated) {
		httpx.Error(w, http.StatusUnauthorized, "unauthenticated", "Sign in is required", false)
		return
	}
	httpx.Error(w, http.StatusServiceUnavailable, "database_unavailable", "Database is not ready", true)
}

func RequireAdmin(w http.ResponseWriter, req *http.Request, pool *pgxpool.Pool) (Principal, bool) {
	principal, err := Current(req, pool)
	if err != nil {
		WriteAccessError(w, err)
		return Principal{}, false
	}
	if principal.Role != "admin" {
		httpx.Error(w, http.StatusForbidden, "forbidden", "Admin access is required", false)
		return Principal{}, false
	}
	return principal, true
}

func bearer(req *http.Request) string {
	token, ok := strings.CutPrefix(req.Header.Get("Authorization"), "Bearer ")
	if !ok || len(token) != 43 {
		return ""
	}
	decoded, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(decoded) != 32 {
		return ""
	}
	return token
}

func issue(ctx context.Context, pool *pgxpool.Pool, userID string) (string, time.Time, error) {
	var raw [32]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "", time.Time{}, err
	}
	token := base64.RawURLEncoding.EncodeToString(raw[:])
	hash := sha256.Sum256([]byte(token))
	var expires time.Time
	err := pool.QueryRow(ctx, `INSERT INTO sessions (user_id, token_hash, expires_at)
		SELECT id, $2, now() + interval '7 days' FROM users WHERE id = $1 AND active
		RETURNING expires_at`, userID, hash[:]).Scan(&expires)
	return token, expires, err
}
