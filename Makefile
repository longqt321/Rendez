.PHONY: help demo db db-recreate down migrate seed api api-dev build-web mobile-deps mobile check check-backend check-mobile integration integration-ui format

help:
	@echo "demo            Start Docker API + OCR + DB, migrate, seed and wait ready"
	@echo "db/down         Start/stop local PostgreSQL (preserve data)"
	@echo "db-recreate     Recreate dev PostgreSQL container (preserve data)"
	@echo "migrate/seed    Apply active migrations / seed local demo records"
	@echo "api/api-dev     Run normal/development API"
	@echo "mobile-deps     Install locked Flutter dependencies"
	@echo "mobile          Run Flutter (select a device)"
	@echo "build-web       Compile Flutter web"
	@echo "check           Analyze and test backend + mobile"
	@echo "integration     Run tests in fresh Docker PostgreSQL (auto cleanup)"
	@echo "integration-ui  Test Flutter against real HTTP + Docker PostgreSQL"
	@echo "format          Format Go and Dart sources"

demo:
	docker compose -f backend/docker-compose.yml build api
	$(MAKE) db
	docker compose -f backend/docker-compose.yml run --rm api -migrate
	docker compose -f backend/docker-compose.yml run --rm api -seed-demo
	docker compose -f backend/docker-compose.yml up -d --wait --wait-timeout 60 api


db:
	$(MAKE) -C backend local-db

db-recreate:
	$(MAKE) -C backend local-recreate

down:
	$(MAKE) -C backend local-down

migrate:
	$(MAKE) -C backend migrate

seed:
	$(MAKE) -C backend seed-demo

api:
	$(MAKE) -C backend run

api-dev:
	$(MAKE) -C backend run-dev

mobile-deps:
	cd mobile && flutter pub get --enforce-lockfile

build-web:
	cd mobile && flutter build web --no-pub

mobile:
	cd mobile && flutter run

check: check-backend check-mobile

check-backend:
	$(MAKE) -C backend check

check-mobile:
	cd mobile && flutter analyze --no-pub
	cd mobile && flutter test --no-pub

integration:
	$(MAKE) -C backend test-integration

integration-ui:
	RUN_FLUTTER_INTEGRATION=1 $(MAKE) -C backend test-integration

format:
	cd backend && gofmt -w cmd internal
	cd mobile && dart format lib test
