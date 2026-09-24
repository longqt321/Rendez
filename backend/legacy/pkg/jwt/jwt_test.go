package jwt

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"rendez-backend/internal/model"
)

func TestJWTGenerateAndVerify(t *testing.T) {
	secret := "test-secret-key-1234567890"
	userID := uuid.New()
	role := model.RoleUser

	token, err := GenerateAccessToken(userID, role, secret, 5*time.Minute)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	claims, err := VerifyAccessToken(token, secret)
	if err != nil {
		t.Fatalf("Failed to verify token: %v", err)
	}

	if claims.UserID != userID {
		t.Errorf("Expected userID %v, got %v", userID, claims.UserID)
	}
	if claims.Role != role {
		t.Errorf("Expected role %v, got %v", role, claims.Role)
	}

	tamperedToken := token + "tamper"
	_, err = VerifyAccessToken(tamperedToken, secret)
	if err == nil {
		t.Errorf("Expected verification to fail for tampered token")
	}

	expiredToken, err := GenerateAccessToken(userID, role, secret, -1*time.Minute)
	if err != nil {
		t.Fatalf("Failed to generate expired token: %v", err)
	}

	_, err = VerifyAccessToken(expiredToken, secret)
	if err == nil || err != ErrTokenExpired {
		t.Errorf("Expected ErrTokenExpired, got %v", err)
	}
}
