package database

import (
	"fmt"
	"log"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func Connect(dbURL string) (*sqlx.DB, error) {
	db, err := sqlx.Open("postgres", dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open postgres connection: %w", err)
	}

	// Connection Pool Settings for high-throughput Senior architecture
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(15 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)

	// Retry connection with backoff to handle database startup timing
	maxRetries := 10
	retryDelay := 3 * time.Second
	for i := 1; i <= maxRetries; i++ {
		if err := db.Ping(); err == nil {
			log.Println("Successfully connected to PostgreSQL database.")
			return db, nil
		} else {
			log.Printf("Database ping attempt %d/%d failed: %v", i, maxRetries, err)
			if i < maxRetries {
				time.Sleep(retryDelay)
			}
		}
	}

	db.Close()
	return nil, fmt.Errorf("failed to connect to database after %d attempts", maxRetries)
}
