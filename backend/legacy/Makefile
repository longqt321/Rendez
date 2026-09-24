.PHONY: run build test migrate-up migrate-down docker-up docker-down

include .env
export $(shell sed 's/=.*//' .env 2>/dev/null)

DB_URL=postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)

run:
	go run cmd/api/main.go

build:
	go build -o bin/rendez-api cmd/api/main.go

test:
	go test -v ./...

docker-up:
	docker compose up --build -d

docker-down:
	docker compose down

migrate-up:
	@which migrate > /dev/null || (echo "golang-migrate not found in PATH. Install with: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest" && exit 1)
	migrate -path migrations -database "$(DB_URL)" up

migrate-down:
	@which migrate > /dev/null || (echo "golang-migrate not found in PATH" && exit 1)
	migrate -path migrations -database "$(DB_URL)" down 1
