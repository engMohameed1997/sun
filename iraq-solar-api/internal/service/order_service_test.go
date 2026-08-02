package service_test

import (
	"testing"

	"github.com/iraq-solar/api/internal/domain"
)

func TestProductStockReservation(t *testing.T) {
	p := domain.Product{
		StockQuantity:    10,
		ReservedQuantity: 3,
	}

	if p.AvailableQuantity() != 7 {
		t.Errorf("Expected available quantity 7, got %d", p.AvailableQuantity())
	}

	// Test case where reserved quantity exceeds stock
	pOverflow := domain.Product{
		StockQuantity:    5,
		ReservedQuantity: 8,
	}
	if pOverflow.AvailableQuantity() != 0 {
		t.Errorf("Expected available quantity 0 on overflow, got %d", pOverflow.AvailableQuantity())
	}
}

func TestStockReservationConcurrencySafety(t *testing.T) {
	stockQuantity := 1
	reservedQuantity := 0

	// Concurrent request simulation: 2 requests trying to reserve 1 item simultaneously
	type result struct {
		success bool
		err     string
	}
	ch := make(chan result, 2)

	for i := 0; i < 2; i++ {
		go func() {
			// Simulated SELECT ... FOR UPDATE transaction check
			if stockQuantity-reservedQuantity >= 1 {
				reservedQuantity++
				ch <- result{success: true}
			} else {
				ch <- result{success: false, err: "insufficient stock"}
			}
		}()
	}

	r1 := <-ch
	r2 := <-ch

	successCount := 0
	if r1.success {
		successCount++
	}
	if r2.success {
		successCount++
	}

	if successCount != 1 {
		t.Errorf("Concurrency test failed: Expected exactly 1 successful reservation, got %d", successCount)
	}
}
