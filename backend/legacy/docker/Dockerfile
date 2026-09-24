# Stage 1: Build binary
FROM golang:1.24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/bin/rendez-api ./cmd/api

# Stage 2: Runtime
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata
ENV TZ=Asia/Ho_Chi_Minh

COPY --from=builder /app/bin/rendez-api /app/rendez-api
COPY --from=builder /app/migrations /app/migrations

EXPOSE 8080

CMD ["/app/rendez-api"]
