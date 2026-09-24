package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

type OCRStatus string

const (
	OCRStatusPendingReview OCRStatus = "pending_review"
	OCRStatusConfirmed     OCRStatus = "confirmed"
)

// JSONB type for PostgreSQL raw OCR results
type JSONB map[string]any

func (j JSONB) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

func (j *JSONB) Scan(value any) error {
	if value == nil {
		*j = nil
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed for JSONB")
	}
	return json.Unmarshal(bytes, j)
}

type OCRResult struct {
	ID              uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	ContributionID  *uuid.UUID `gorm:"type:uuid;index" json:"contribution_id,omitempty"`
	SourceImagePath string     `gorm:"type:text;not null" json:"source_image_path"`
	RawResult       JSONB      `gorm:"type:jsonb" json:"raw_result,omitempty"`
	Status          OCRStatus  `gorm:"type:varchar(30);not null;default:'pending_review';index" json:"status"`
	ReviewedBy      *uuid.UUID `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}
