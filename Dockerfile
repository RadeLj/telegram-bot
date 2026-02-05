# -------- Build stage --------
FROM golang:1.24-bookworm AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app

# -------- Runtime stage --------
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y wkhtmltopdf fonts-dejavu-core && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/app .
COPY --from=builder /app/template.html .

CMD ["./app"]
