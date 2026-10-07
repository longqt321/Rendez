#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
# Each invocation owns its containers/network; concurrent runs do not collide.
project="rendez-test-$$"
ocr_tools=""
compose() {
    docker compose -f docker-compose.test.yml -p "$project" "$@"
}
cleanup() {
    status=$?
    trap - EXIT
    if ! compose down --remove-orphans; then
        echo "Could not clean test containers for $project" >&2
        status=1
    fi
    if [ -n "$ocr_tools" ]; then
        rm -f "$ocr_tools/tesseract"
        rmdir "$ocr_tools"
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Use the same real Vietnamese OCR engine as the Docker demo; no mock OCR.
if ! command -v tesseract >/dev/null 2>&1; then
    docker compose -f docker-compose.yml build api
    ocr_tools=$(mktemp -d)
    cat > "$ocr_tools/tesseract" <<'OCR'
#!/bin/sh
exec docker run --rm -i --entrypoint tesseract rendez-local-api stdin stdout -l vie+eng --psm 6 < "$1"
OCR
    chmod +x "$ocr_tools/tesseract"
    export PATH="$ocr_tools:$PATH"
fi

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
