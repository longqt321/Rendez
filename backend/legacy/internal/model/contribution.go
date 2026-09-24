package model

import (
	"time"

	"github.com/google/uuid"
)

type ContributionType string

const (
	ContributionTypeBill      ContributionType = "bill"
	ContributionTypeMenuPhoto ContributionType = "menu_photo"
)

type ContributionStatus string

const (
	ContributionStatusPendingAuto    ContributionStatus = "pending_auto"
	ContributionStatusPendingManual  ContributionStatus = "pending_manual"
	ContributionStatusApproved       ContributionStatus = "approved"
	ContributionStatusRejectedAuto   ContributionStatus = "rejected_auto"
	ContributionStatusRejectedManual ContributionStatus = "rejected_manual"
)

type Contribution struct {
	ID            uuid.UUID          `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	ContributorID uuid.UUID          `gorm:"type:uuid;not null;index" json:"contributor_id"`
	PlaceID       *uuid.UUID         `gorm:"type:uuid;index" json:"place_id,omitempty"`
	Type          ContributionType   `gorm:"type:varchar(30);not null" json:"type"`
	ImagePath     string             `gorm:"type:text;not null" json:"image_path"`
	CapturedAt    *time.Time         `json:"captured_at,omitempty"`
	Status        ContributionStatus `gorm:"type:varchar(30);not null;default:'pending_auto';index" json:"status"`
	RejectReason  *string            `gorm:"type:text" json:"reject_reason,omitempty"`
	ReviewedBy    *uuid.UUID         `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt    *time.Time         `json:"reviewed_at,omitempty"`
	CreatedAt     time.Time          `json:"created_at"`

	Place Place `gorm:"foreignKey:PlaceID" json:"place,omitempty"`
}
