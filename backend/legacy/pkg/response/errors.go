package response

import "net/http"

// Domain Error Codes (NFR-23)
const (
	ErrInternalServer        = "INTERNAL_SERVER_ERROR"
	ErrValidationFailed      = "VALIDATION_FAILED"
	ErrBadRequest            = "BAD_REQUEST"
	ErrNotFound              = "NOT_FOUND"
	ErrUnauthorized          = "UNAUTHORIZED"
	ErrForbidden             = "FORBIDDEN"
	ErrInvalidCredentials    = "AUTH_INVALID_CREDENTIALS"
	ErrEmailAlreadyExists    = "AUTH_EMAIL_EXISTS"
	ErrTokenExpired          = "AUTH_TOKEN_EXPIRED"
	ErrTokenInvalid          = "AUTH_TOKEN_INVALID"
	ErrPlaceNotFound         = "PLACE_NOT_FOUND"
	ErrMenuItemNotFound      = "MENU_ITEM_NOT_FOUND"
	ErrUploadTooLarge        = "UPLOAD_TOO_LARGE"
	ErrInvalidFileType       = "INVALID_FILE_TYPE"
	ErrOCRFailed             = "OCR_SERVICE_FAILED"
	ErrOCRTimeout            = "OCR_SERVICE_TIMEOUT"
	ErrContributionNotFound  = "CONTRIBUTION_NOT_FOUND"
	ErrCannotReviewOwnAction = "CANNOT_REVIEW_OWN_ACTION"
)

type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details any    `json:"details,omitempty"`
}

type AppError struct {
	HTTPStatus int
	Code       string
	Message    string
	Details    any
}

func (e *AppError) Error() string {
	return e.Message
}

func NewAppError(status int, code string, message string) *AppError {
	return &AppError{
		HTTPStatus: status,
		Code:       code,
		Message:    message,
	}
}

func ErrInternal(msg string) *AppError {
	if msg == "" {
		msg = "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau."
	}
	return NewAppError(http.StatusInternalServerError, ErrInternalServer, msg)
}

func ErrValidate(msg string, details any) *AppError {
	return &AppError{
		HTTPStatus: http.StatusBadRequest,
		Code:       ErrValidationFailed,
		Message:    msg,
		Details:    details,
	}
}
