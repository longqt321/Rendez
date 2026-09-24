package middleware

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}
		c.Header("X-Request-ID", requestID)
		c.Set("request_id", requestID)

		c.Next()

		latency := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path

		// Luôn tuân thủ SEC-05: Tuyệt đối KHÔNG log Authorization header, token hoặc password
		log.Printf("[REQ-ID: %s] | %3d | %13v | %15s | %-7s %#v",
			requestID,
			statusCode,
			latency,
			clientIP,
			method,
			path,
		)
	}
}
