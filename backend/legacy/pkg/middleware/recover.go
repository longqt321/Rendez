package middleware

import (
	"fmt"
	"log"
	"runtime/debug"

	"github.com/gin-gonic/gin"

	"rendez-backend/pkg/response"
)

func RecoverMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				errStr := fmt.Sprintf("%v", r)
				stack := string(debug.Stack())
				log.Printf("[PANIC RECOVER] %s\n%s", errStr, stack)

				response.ErrorWithStatus(
					c,
					500,
					response.ErrInternalServer,
					"Hệ thống gặp sự cố ngoài dự kiến",
				)
				c.Abort()
			}
		}()
		c.Next()
	}
}
