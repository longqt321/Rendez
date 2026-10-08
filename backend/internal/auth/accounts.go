package auth

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/mail"
	"strings"

	"rendez-backend/internal/httpx"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func registerAccounts(r chi.Router, pool *pgxpool.Pool) {
	for _, path := range []string{"/v1/auth/register", "/v1/auth/login"} {
		r.Post(path, func(w http.ResponseWriter, req *http.Request) {
			var input struct {
				Email    string `json:"email"`
				Password string `json:"password"`
				Name     string `json:"display_name"`
			}
			decoder := json.NewDecoder(http.MaxBytesReader(w, req.Body, 4096))
			decoder.DisallowUnknownFields()
			if decoder.Decode(&input) != nil || decoder.Decode(new(any)) != io.EOF {
				httpx.Error(w, 400, "invalid_json", "Dữ liệu gửi không hợp lệ", false)
				return
			}
			input.Email = strings.ToLower(strings.TrimSpace(input.Email))
			input.Name = strings.TrimSpace(input.Name)
			addr, err := mail.ParseAddress(input.Email)
			if err != nil || addr.Address != input.Email || len(input.Email) > 254 || len(input.Password) < 8 || len(input.Password) > 256 {
				httpx.Error(w, 422, "validation_error", "Nhập email hợp lệ và mật khẩu từ 8 đến 256 ký tự", false)
				return
			}
			var id, name, role, stored string
			if req.URL.Path == "/v1/auth/register" {
				if len(input.Name) == 0 || len(input.Name) > 200 {
					httpx.Error(w, 422, "validation_error", "Tên không được trống hoặc quá dài", false)
					return
				}
				hash, err := hashPassword(input.Password)
				if err != nil {
					WriteAccessError(w, err)
					return
				}
				err = pool.QueryRow(req.Context(), `INSERT INTO users(display_name,email,password_hash,role) VALUES($1,$2,$3,'user') RETURNING id::text,display_name,role`, input.Name, input.Email, hash).Scan(&id, &name, &role)
				var pgErr *pgconn.PgError
				if errors.As(err, &pgErr) && pgErr.Code == "23505" {
					httpx.Error(w, 409, "email_exists", "Email đã được sử dụng", false)
					return
				}
				if err != nil {
					WriteAccessError(w, err)
					return
				}
			} else {
				err := pool.QueryRow(req.Context(), `SELECT id::text,display_name,role,password_hash FROM users WHERE email=$1 AND active AND password_hash IS NOT NULL`, input.Email).Scan(&id, &name, &role, &stored)
				if errors.Is(err, pgx.ErrNoRows) || (err == nil && !validPassword(input.Password, stored)) {
					httpx.Error(w, 401, "invalid_credentials", "Email hoặc mật khẩu không chính xác", false)
					return
				}
				if err != nil {
					WriteAccessError(w, err)
					return
				}
			}
			token, expires, err := issue(req.Context(), pool, id)
			if err != nil {
				WriteAccessError(w, err)
				return
			}
			status := 200
			if req.URL.Path == "/v1/auth/register" {
				status = 201
			}
			httpx.JSON(w, status, map[string]any{"token": token, "expires_at": expires, "user": map[string]string{"id": id, "display_name": name, "email": input.Email, "role": role}})
		})
	}
}

// SeedDemoAdmin creates the local demonstration admin or updates its seeded password.
func SeedDemoAdmin(ctx context.Context, pool *pgxpool.Pool) (string, error) {
	hash, err := hashPassword("123123123")
	if err != nil {
		return "", err
	}
	_, err = pool.Exec(ctx, `INSERT INTO users(display_name,email,password_hash,role) VALUES('Demo Admin','longqt321@rendez.local',$1,'admin') ON CONFLICT(email) DO UPDATE
SET password_hash = EXCLUDED.password_hash`, hash)
	if err != nil {
		return "", err
	}
	var id string
	err = pool.QueryRow(ctx, `SELECT id::text FROM users WHERE email='longqt321@rendez.local' AND role='admin'`).Scan(&id)
	return id, err
}
