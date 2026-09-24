//go:build !dev

package auth

import (
	"context"
	"errors"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func ValidateBuild(string) error { return nil }

func SeedDev(context.Context, *pgxpool.Pool, string) error {
	return errors.New("development seed is unavailable in this build")
}

func registerDev(chi.Router, *pgxpool.Pool, string) {}
