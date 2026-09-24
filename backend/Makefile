.PHONY: local-db local-down migrate run build test test-integration verify-m0

# Disposable local credentials; an explicitly exported URL takes precedence.
export DATABASE_URL ?= postgres://rendez:rendez_local@127.0.0.1:55432/rendez_core?sslmode=disable
export HTTP_ADDR ?= 127.0.0.1:8080

local-db:
	docker compose up -d --wait --wait-timeout 60 db

local-down:
	docker compose down

migrate:
	go run ./cmd/api -migrate

run:
	go run ./cmd/api

build:
	go build -o bin/rendez-api ./cmd/api

test:
	go test ./...

test-integration:
	@TEST_DATABASE_URL="$$DATABASE_URL" go test -tags=integration -count=1 -v ./cmd/api

verify-m0: build test test-integration
