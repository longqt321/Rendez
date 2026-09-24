package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PlaceStatus string

const (
	PlaceStatusDraft  PlaceStatus = "draft"
	PlaceStatusActive PlaceStatus = "active"
	PlaceStatusHidden PlaceStatus = "hidden"
)

type Place struct {
	ID          uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name        string         `gorm:"type:varchar(255);not null" json:"name"`
	Category    string         `gorm:"type:varchar(100);not null;index" json:"category"`
	Address     string         `gorm:"type:text;not null" json:"address"`
	Latitude    *float64       `gorm:"type:double precision" json:"latitude,omitempty"`
	Longitude   *float64       `gorm:"type:double precision" json:"longitude,omitempty"`
	Status      PlaceStatus    `gorm:"type:varchar(20);not null;default:'draft';index" json:"status"`
	Verified    bool           `gorm:"type:boolean;not null;default:false" json:"verified"`
	CreatedBy   *uuid.UUID     `gorm:"type:uuid" json:"created_by,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	// Relationships
	MenuItems  []MenuItem  `gorm:"foreignKey:PlaceID;constraint:OnDelete:CASCADE" json:"menu_items,omitempty"`
	MenuImages []MenuImage `gorm:"foreignKey:PlaceID;constraint:OnDelete:CASCADE" json:"menu_images,omitempty"`
}
