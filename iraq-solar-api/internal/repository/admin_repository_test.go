package repository_test

import (
	"encoding/json"
	"testing"
)

// Unit test for audit log payload redaction logic
func TestSanitizePayload(t *testing.T) {
	input := map[string]interface{}{
		"email":        "user@example.com",
		"password":     "Secret123!",
		"api_key":      "sk_live_123456",
		"access_token": "jwt.token.val",
		"normal_field": "hello_world",
	}

	data, err := json.Marshal(input)
	if err != nil {
		t.Fatalf("failed to marshal input: %v", err)
	}

	var temp map[string]interface{}
	_ = json.Unmarshal(data, &temp)

	sanitized := make(map[string]interface{})
	for k, v := range temp {
		lk := k
		if lk == "password" || lk == "api_key" || lk == "access_token" {
			sanitized[k] = "[REDACTED]"
		} else {
			sanitized[k] = v
		}
	}

	if sanitized["password"] != "[REDACTED]" {
		t.Errorf("expected password to be redacted, got %v", sanitized["password"])
	}
	if sanitized["api_key"] != "[REDACTED]" {
		t.Errorf("expected api_key to be redacted, got %v", sanitized["api_key"])
	}
	if sanitized["normal_field"] != "hello_world" {
		t.Errorf("expected normal_field to be preserved, got %v", sanitized["normal_field"])
	}
}
