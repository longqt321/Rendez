package auth

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"rendez-backend/config"
	"rendez-backend/internal/model"
	"rendez-backend/pkg/jwt"
	"rendez-backend/pkg/response"
)

type Service interface {
	Register(req *RegisterRequest) (*AuthResponse, error)
	Login(req *LoginRequest) (*AuthResponse, error)
	Logout(rawRefreshToken string) error
	RefreshToken(rawRefreshToken string) (*AuthResponse, error)
	GetProfile(userID uuid.UUID) (*UserProfileResponse, error)
}

type service struct {
	db  *gorm.DB
	cfg *config.Config
}

func NewService(db *gorm.DB, cfg *config.Config) Service {
	return &service{db: db, cfg: cfg}
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Username string `json:"username"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type UserProfileResponse struct {
	ID        uuid.UUID      `json:"id"`
	Email     string         `json:"email"`
	Username  string         `json:"username,omitempty"`
	Role      model.UserRole `json:"role"`
	CreatedAt time.Time      `json:"created_at"`
}

type AuthResponse struct {
	User   UserProfileResponse `json:"user"`
	Tokens jwt.TokenPair       `json:"tokens"`
}

func (s *service) Register(req *RegisterRequest) (*AuthResponse, error) {
	var count int64
	s.db.Model(&model.User{}).Where("email = ?", req.Email).Count(&count)
	if count > 0 {
		return nil, response.NewAppError(http.StatusConflict, response.ErrEmailAlreadyExists, "Email đã được sử dụng")
	}

	hashedPassword, err := HashPassword(req.Password)
	if err != nil {
		return nil, response.ErrInternal("Không thể mã hóa mật khẩu")
	}

	// Always role 'user' on public register (SEC-07: anti mass-assignment)
	user := model.User{
		Email:        req.Email,
		Username:     req.Username,
		PasswordHash: hashedPassword,
		Role:         model.RoleUser,
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, response.ErrInternal("Lỗi lưu thông tin người dùng")
	}

	return s.createSession(&user)
}

func (s *service) Login(req *LoginRequest) (*AuthResponse, error) {
	var user model.User
	if err := s.db.Where("email = ?", req.Email).First(&user).Error; err != nil {
		// Generic message to avoid user enumeration (UC 4.2.1 flow 5a)
		return nil, response.NewAppError(http.StatusUnauthorized, response.ErrInvalidCredentials, "Email hoặc mật khẩu không chính xác")
	}

	if !VerifyPassword(user.PasswordHash, req.Password) {
		return nil, response.NewAppError(http.StatusUnauthorized, response.ErrInvalidCredentials, "Email hoặc mật khẩu không chính xác")
	}

	return s.createSession(&user)
}

func (s *service) Logout(rawRefreshToken string) error {
	if rawRefreshToken == "" {
		return nil
	}
	tokenHash := jwt.HashRefreshToken(rawRefreshToken)
	return s.db.Where("token_hash = ?", tokenHash).Delete(&model.RefreshToken{}).Error
}

func (s *service) RefreshToken(rawRefreshToken string) (*AuthResponse, error) {
	tokenHash := jwt.HashRefreshToken(rawRefreshToken)

	var tokenRecord model.RefreshToken
	if err := s.db.Preload("User").Where("token_hash = ? AND expires_at > ?", tokenHash, time.Now()).First(&tokenRecord).Error; err != nil {
		return nil, response.NewAppError(http.StatusUnauthorized, response.ErrTokenInvalid, "Refresh token không hợp lệ hoặc đã hết hạn")
	}

	// Invalidate old refresh token (Token rotation)
	s.db.Delete(&tokenRecord)

	return s.createSession(&tokenRecord.User)
}

func (s *service) GetProfile(userID uuid.UUID) (*UserProfileResponse, error) {
	var user model.User
	if err := s.db.First(&user, "id = ?", userID).Error; err != nil {
		return nil, response.NewAppError(http.StatusNotFound, response.ErrNotFound, "Không tìm thấy người dùng")
	}

	return &UserProfileResponse{
		ID:        user.ID,
		Email:     user.Email,
		Username:  user.Username,
		Role:      user.Role,
		CreatedAt: user.CreatedAt,
	}, nil
}

func (s *service) createSession(user *model.User) (*AuthResponse, error) {
	accessToken, err := jwt.GenerateAccessToken(user.ID, user.Role, s.cfg.JWTSecret, s.cfg.JWTAccessTTL)
	if err != nil {
		return nil, response.ErrInternal("Không thể tạo access token")
	}

	rawRefreshToken, refreshHash := jwt.GenerateRefreshToken()
	refreshTokenExpires := time.Now().Add(s.cfg.JWTRefreshTTL)

	record := model.RefreshToken{
		UserID:    user.ID,
		TokenHash: refreshHash,
		ExpiresAt: refreshTokenExpires,
	}

	if err := s.db.Create(&record).Error; err != nil {
		return nil, response.ErrInternal("Không thể lưu phiên đăng nhập")
	}

	return &AuthResponse{
		User: UserProfileResponse{
			ID:        user.ID,
			Email:     user.Email,
			Username:  user.Username,
			Role:      user.Role,
			CreatedAt: user.CreatedAt,
		},
		Tokens: jwt.TokenPair{
			AccessToken:  accessToken,
			RefreshToken: rawRefreshToken,
			ExpiresIn:    int64(s.cfg.JWTAccessTTL.Seconds()),
		},
	}, nil
}
