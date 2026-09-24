package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"rendez-backend/pkg/middleware"
	"rendez-backend/pkg/response"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, response.ErrValidate("Dữ liệu đăng ký không hợp lệ: email đúng chuẩn và mật khẩu tối thiểu 6 ký tự", err.Error()))
		return
	}

	res, err := h.service.Register(&req)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, http.StatusCreated, res)
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, response.ErrValidate("Dữ liệu đăng nhập không hợp lệ", err.Error()))
		return
	}

	res, err := h.service.Login(&req)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, http.StatusOK, res)
}

func (h *Handler) Logout(c *gin.Context) {
	var req RefreshRequest
	_ = c.ShouldBindJSON(&req)

	if err := h.service.Logout(req.RefreshToken); err != nil {
		response.Error(c, response.ErrInternal("Lỗi khi đăng xuất"))
		return
	}

	response.Success(c, http.StatusOK, gin.H{"message": "Đăng xuất thành công"})
}

func (h *Handler) Refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, response.ErrValidate("Thiếu refresh_token", err.Error()))
		return
	}

	res, err := h.service.RefreshToken(req.RefreshToken)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, http.StatusOK, res)
}

func (h *Handler) Me(c *gin.Context) {
	userID, ok := middleware.GetCurrentUserID(c)
	if !ok {
		response.ErrorWithStatus(c, http.StatusUnauthorized, response.ErrUnauthorized, "Yêu cầu đăng nhập")
		return
	}

	res, err := h.service.GetProfile(userID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, http.StatusOK, res)
}
