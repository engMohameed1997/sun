package service

import (
	"net/http"
	"sync"
	"github.com/gorilla/websocket"
	"github.com/iraq-solar/api/internal/repository"
)

type NotificationService struct {
	repo     *repository.NotificationRepository
	upgrader websocket.Upgrader
	clients  map[*websocket.Conn]string // conn -> userID
	mu       sync.Mutex
}

func NewNotificationService(repo *repository.NotificationRepository) *NotificationService {
	return &NotificationService{
		repo: repo,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
		clients: make(map[*websocket.Conn]string),
	}
}

func (s *NotificationService) HandleWebSocket(w http.ResponseWriter, r *http.Request, userID string) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	s.mu.Lock()
	s.clients[conn] = userID
	s.mu.Unlock()

	defer func() {
		s.mu.Lock()
		delete(s.clients, conn)
		s.mu.Unlock()
		conn.Close()
	}()

	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			break
		}
	}
}
