#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
# Each invocation owns its containers/network; concurrent runs do not collide.
project="rendez-test-$$"
compose() {
    docker compose -f docker-compose.test.yml -p "$project" "$@"
}
cleanup() {
    status=$?
    trap - EXIT
    if ! compose down --volumes --remove-orphans; then
        echo "Could not clean test containers for $project" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

compose up -d --wait --wait-timeout 60 db
address=$(compose port db 5432)
case "$address" in
    127.0.0.1:*) port=${address##*:} ;;
    *) echo "Unexpected test PostgreSQL address" >&2; exit 1 ;;
esac
case "$port" in
    ''|*[!0-9]*) echo "Invalid test PostgreSQL port" >&2; exit 1 ;;
esac
# Override both URLs so exported dev/system configuration cannot affect tests.
export DATABASE_URL="postgres://rendez:rendez_test_only@127.0.0.1:$port/rendez_test?sslmode=disable"
export TEST_DATABASE_URL="$DATABASE_URL"
export APP_ENV=test
go test -tags='integration dev' -count=1 -v ./cmd/api "$@"
