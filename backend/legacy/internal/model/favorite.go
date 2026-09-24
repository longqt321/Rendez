package model

import (
	"time"

	"github.com/google/uuid"
)

type Favorite struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:uq_favorites_user_place" json:"user_id"`
	PlaceID   uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:uq_favorites_user_place" json:"place_id"`
	CreatedAt time.Time `json:"created_at"`

	Place Place `gorm:"foreignKey:PlaceID" json:"place,omitempty"`
}
