.PHONY: help db down migrate seed api api-dev mobile-deps mobile check check-backend check-mobile integration format

help:
	@echo "db/down         Start/stop local PostgreSQL (preserve data)"
	@echo "migrate/seed    Apply active migrations / seed dev fixtures"
	@echo "api/api-dev     Run normal/development API"
	@echo "mobile-deps     Install locked Flutter dependencies"
	@echo "mobile          Run Flutter (select a device)"
	@echo "check           Analyze and test backend + mobile"
	@echo "integration     Run isolated PostgreSQL tests (requires db)"
	@echo "format          Format Go and Dart sources"

db:
	$(MAKE) -C backend local-db

down:
	$(MAKE) -C backend local-down

migrate:
	$(MAKE) -C backend migrate

seed:
	$(MAKE) -C backend seed-dev

api:
	$(MAKE) -C backend run

api-dev:
	$(MAKE) -C backend run-dev

mobile-deps:
	cd mobile && flutter pub get --enforce-lockfile

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
	$(MAKE) -C backend verify-m1

format:
	cd backend && gofmt -w cmd internal
	cd mobile && dart format lib test
