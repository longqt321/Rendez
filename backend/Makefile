.PHONY: local-db local-down migrate seed-dev run run-dev build test test-integration verify-m0 verify-m1

# Disposable local credentials; an explicitly exported URL takes precedence.
export DATABASE_URL ?= postgres://rendez:rendez_local@127.0.0.1:55432/rendez_core?sslmode=disable
export HTTP_ADDR ?= 127.0.0.1:8080
export APP_ENV ?= development

local-db:
	docker compose up -d --wait --wait-timeout 60 db

local-down:
	docker compose down

migrate:
	go run ./cmd/api -migrate

seed-dev:
	go run -tags=dev ./cmd/api -seed-dev

run:
	go run ./cmd/api

run-dev:
	go run -tags=dev ./cmd/api

build:
	go build -o bin/rendez-api ./cmd/api

test:
	go test ./...

test-integration:
	@TEST_DATABASE_URL="$$DATABASE_URL" go test -tags=integration -count=1 -v ./cmd/api

verify-m0: build test test-integration

verify-m1: test
	@TEST_DATABASE_URL="$$DATABASE_URL" go test -tags='integration dev' -count=1 -run TestM1Sessions ./cmd/api
