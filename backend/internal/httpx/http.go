package httpx

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func JSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(value); err != nil {
		slog.Error("HTTP response write failed")
	}
}

func Error(w http.ResponseWriter, status int, code, message string, retryable bool) {
	JSON(w, status, map[string]any{"error": map[string]any{
		"code": code, "message": message, "retryable": retryable,
	}})
}
