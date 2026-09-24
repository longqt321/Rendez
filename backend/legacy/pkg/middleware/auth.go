package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"rendez-backend/internal/model"
	"rendez-backend/pkg/jwt"
	"rendez-backend/pkg/response"
)

const (
	CtxUserIDKey = "current_user_id"
	CtxRoleKey   = "current_user_role"
)

func RequireAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrUnauthorized, "Yêu cầu đăng nhập để thực hiện chức năng này")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrTokenInvalid, "Định dạng Authorization header không hợp lệ")
			c.Abort()
			return
		}

		claims, err := jwt.VerifyAccessToken(parts[1], secret)
		if err != nil {
			if errors.Is(err, jwt.ErrTokenExpired) {
				response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrTokenExpired, "Phiên đăng nhập đã hết hạn")
			} else {
				response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrTokenInvalid, "Token xác thực không hợp lệ")
			}
			c.Abort()
			return
		}

		c.Set(CtxUserIDKey, claims.UserID)
		c.Set(CtxRoleKey, claims.Role)
		c.Next()
	}
}

func RequireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get(CtxRoleKey)
		if !exists {
			response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrUnauthorized, "Yêu cầu xác thực tài khoản")
			c.Abort()
			return
		}

		role, ok := roleVal.(model.UserRole)
		if !ok || role != model.RoleAdmin {
			response.ErrorWithStatus(c, http.StatusForbidden, response.ErrForbidden, "Quyền truy cập bị từ chối. Chỉ dành cho Quản trị viên.")
			c.Abort()
			return
		}

		c.Next()
	}
}

func GetCurrentUserID(c *gin.Context) (uuid.UUID, bool) {
	val, exists := c.Get(CtxUserIDKey)
	if !exists {
		return uuid.Nil, false
	}
	id, ok := val.(uuid.UUID)
	return id, ok
}

func GetCurrentUserRole(c *gin.Context) (model.UserRole, bool) {
	val, exists := c.Get(CtxRoleKey)
	if !exists {
		return "", false
	}
	role, ok := val.(model.UserRole)
	return role, ok
}
