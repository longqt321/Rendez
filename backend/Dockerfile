FROM golang:1.26-bookworm AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /rendez-api ./cmd/api

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends tesseract-ocr tesseract-ocr-vie tesseract-ocr-eng ca-certificates curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /rendez-api /usr/local/bin/rendez-api
COPY migrations/core migrations/core
RUN useradd --system --uid 10001 rendez && mkdir -p /app/data/uploads && chown -R rendez /app/data
USER rendez
ENTRYPOINT ["rendez-api"]
