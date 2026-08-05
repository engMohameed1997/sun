package cache

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisCache struct {
	client *redis.Client
}

func NewRedisCache(redisURL string) *RedisCache {
	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		// Fallback: try parsing as host:port
		opts = &redis.Options{
			Addr:        redisURL,
			DialTimeout: 2 * time.Second,
		}
	}
	opts.DialTimeout = 2 * time.Second

	client := redis.NewClient(opts)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("Redis Notice: Unable to connect to Redis at %s (%v). System will operate in database-fallback mode.", redisURL, err)
		return &RedisCache{client: nil}
	}

	log.Printf("Redis Cache connected successfully at %s", redisURL)
	return &RedisCache{client: client}
}

func (r *RedisCache) IsAvailable() bool {
	return r != nil && r.client != nil
}

func (r *RedisCache) Get(ctx context.Context, key string) (string, error) {
	if !r.IsAvailable() {
		return "", errors.New("redis unavailable")
	}
	return r.client.Get(ctx, key).Result()
}

func (r *RedisCache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	if !r.IsAvailable() {
		return nil
	}
	return r.client.Set(ctx, key, value, ttl).Err()
}

func (r *RedisCache) SetNX(ctx context.Context, key string, value interface{}, ttl time.Duration) (bool, error) {
	if !r.IsAvailable() {
		return true, nil // Allow event processing if Redis unavailable
	}
	return r.client.SetNX(ctx, key, value, ttl).Result()
}

func (r *RedisCache) DeletePattern(ctx context.Context, pattern string) error {
	if !r.IsAvailable() {
		return nil
	}
	var cursor uint64
	for {
		keys, nextCursor, err := r.client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return err
		}
		if len(keys) > 0 {
			_ = r.client.Del(ctx, keys...).Err()
		}
		cursor = nextCursor
		if cursor == 0 {
			break
		}
	}
	return nil
}
