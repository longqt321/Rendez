package response

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

type SuccessEnvelope struct {
	Data any `json:"data"`
	Meta any `json:"meta,omitempty"`
}

type ErrorEnvelope struct {
	Error ErrorPayload `json:"error"`
}

func Success(c *gin.Context, status int, data any, meta ...any) {
	var m any
	if len(meta) > 0 {
		m = meta[0]
	}
	c.JSON(status, SuccessEnvelope{
		Data: data,
		Meta: m,
	})
}

func Error(c *gin.Context, err error) {
	var appErr *AppError
	if errors.As(err, &appErr) {
		c.JSON(appErr.HTTPStatus, ErrorEnvelope{
			Error: ErrorPayload{
				Code:    appErr.Code,
				Message: appErr.Message,
				Details: appErr.Details,
			},
		})
		return
	}

	// Default unhandled error
	c.JSON(http.StatusInternalServerError, ErrorEnvelope{
		Error: ErrorPayload{
			Code:    ErrInternalServer,
			Message: "Đã có lỗi xảy ra từ phía máy chủ",
		},
	})
}

func ErrorWithStatus(c *gin.Context, status int, code string, message string) {
	c.JSON(status, ErrorEnvelope{
		Error: ErrorPayload{
			Code:    code,
			Message: message,
		},
	})
}
