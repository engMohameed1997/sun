# Step 1: Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

ENV GOTOOLCHAIN=auto

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build lightweight static Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o iraq-solar-api ./cmd/api/main.go

# Step 2: Production Minimal Stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/iraq-solar-api .

EXPOSE 8080

CMD ["./iraq-solar-api"]
