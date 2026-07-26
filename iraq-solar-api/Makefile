.PHONY: run test test-endpoints build docker-up docker-down

run:
	go run cmd/api/main.go

test:
	go test -v ./...

test-endpoints:
	go run cmd/tester/main.go

build:
	go build -o bin/iraq-solar-api cmd/api/main.go

docker-up:
	docker-compose up -d --build

docker-down:
	docker-compose down
