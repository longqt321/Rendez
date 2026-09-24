package auth

import (
	"testing"
)

func TestHashAndVerifyPassword(t *testing.T) {
	password := "Secret123!"

	hash1, err := HashPassword(password)
	if err != nil {
		t.Fatalf("Failed to hash password: %v", err)
	}

	hash2, err := HashPassword(password)
	if err != nil {
		t.Fatalf("Failed to hash password: %v", err)
	}

	// SEC-02: Random salt makes each hash distinct
	if hash1 == hash2 {
		t.Errorf("Expected hashes to differ due to random salt, but got equal: %s", hash1)
	}

	// Verify correct password
	if !VerifyPassword(hash1, password) {
		t.Errorf("Expected password verification to succeed")
	}

	// Verify incorrect password
	if VerifyPassword(hash1, "WrongPassword") {
		t.Errorf("Expected password verification to fail for wrong password")
	}
}
