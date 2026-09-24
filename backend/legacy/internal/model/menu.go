package model

import (
	"time"

	"github.com/google/uuid"
)

type ItemStatus string

const (
	ItemStatusUnconfirmed ItemStatus = "unconfirmed"
	ItemStatusConfirmed   ItemStatus = "confirmed"
)

type MenuItem struct {
	ID          uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	PlaceID     uuid.UUID  `gorm:"type:uuid;not null;index" json:"place_id"`
	Name        string     `gorm:"type:varchar(255);not null" json:"name"`
	Description string     `gorm:"type:text" json:"description,omitempty"`
	Status      ItemStatus `gorm:"type:varchar(20);not null;default:'unconfirmed'" json:"status"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`

	Prices []Price `gorm:"foreignKey:MenuItemID;constraint:OnDelete:CASCADE" json:"prices,omitempty"`
}

type Price struct {
	ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	MenuItemID uuid.UUID `gorm:"type:uuid;not null;index" json:"menu_item_id"`
	Amount     float64   `gorm:"type:numeric(15,2);not null" json:"amount"`
	Currency   string    `gorm:"type:varchar(10);not null;default:'VND'" json:"currency"`
	UpdatedAt  time.Time `json:"updated_at"`
	CreatedAt  time.Time `json:"created_at"`
}

type MenuImage struct {
	ID         uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	PlaceID    uuid.UUID  `gorm:"type:uuid;not null;index" json:"place_id"`
	FilePath   string     `gorm:"type:text;not null" json:"file_path"`
	UploadedBy *uuid.UUID `gorm:"type:uuid" json:"uploaded_by,omitempty"`
	Status     ItemStatus `gorm:"type:varchar(20);not null;default:'unconfirmed'" json:"status"`
	CreatedAt  time.Time  `json:"created_at"`
}
