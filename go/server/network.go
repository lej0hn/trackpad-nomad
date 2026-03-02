package server

import (
    "encoding/json"
    "log"
    "net"
    "net/http"

    "github.com/gorilla/websocket"
)

type Server struct {
    token    string
    upgrader websocket.Upgrader
    injector InputInjector
    registry *DeviceRegistry
}

func NewServer() *Server {
    s := &Server{
        token:    GenerateToken(),
        upgrader: websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }},
        injector: &RobotGoInjector{},
        registry: NewDeviceRegistry("devices.json"),
    }
    return s
}

func GetLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "127.0.0.1"
}

func (s *Server) PrintPairingInfo(port string) {
    ip := GetLocalIP()
    host := ip + ":" + port

    payload := map[string]interface{}{
        "host": host,
        "token": s.token,
        "v": 1,
    }

    b, _ := json.Marshal(payload)
    PrintQR(string(b))
    log.Printf("Pairing payload: %s\n", string(b))
}

func (s *Server) HandleWS(w http.ResponseWriter, r *http.Request) {
    log.Println("WS endpoint hit")
    conn, err := s.upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("upgrade failed:", err)
        return
    }
    defer conn.Close()
    log.Println("New WebSocket connection established")

    authenticated := false

    for {
        var msg map[string]interface{}
        if err := conn.ReadJSON(&msg); err != nil {
            log.Println("read json err:", err)
            return
        }
        t, _ := msg["type"].(string)
        switch t {
        case "auth":
            // 1. Try Refresh Token (Reconnect)
            if refreshToken, ok := msg["refresh_token"].(string); ok {
                deviceID, _ := msg["device_id"].(string)
                if s.registry.ValidateReconnection(deviceID, refreshToken) {
                    authenticated = true
                    log.Printf("Client %s reconnected successfully using refresh token", deviceID)
                    conn.WriteJSON(map[string]interface{}{"type": "auth_ok"})
                } else {
                    log.Println("Authentication failed: invalid refresh token")
                    conn.WriteJSON(map[string]interface{}{"type": "auth_error", "reason": "invalid refresh token"})
                    return
                }
                continue
            }

            // 2. Try QR Token (Initial Pairing)
            token, ok := msg["token"].(string)
            if !ok {
                 log.Println("Authentication failed: no token provided")
                 conn.WriteJSON(map[string]interface{}{"type":"auth_error","reason":"missing token"})
                 return
            }

            if token == s.token {
                authenticated = true
                log.Println("Client successfully authenticated via QR token")
                
                deviceID, _ := msg["device_id"].(string)
                deviceName, _ := msg["device_name"].(string)
                
                if deviceID == "" {
                    deviceID = "dev_" + GenerateToken()[:8] // Basic fallback ID
                }
                
                newRefreshToken := GenerateToken()
                s.registry.RegisterDevice(deviceID, deviceName, newRefreshToken)

                conn.WriteJSON(map[string]interface{}{
                    "type": "auth_ok",
                    "device": map[string]interface{}{
                        "id": deviceID,
                        "name": deviceName,
                        "refresh_token": newRefreshToken,
                    },
                })
            } else {
                log.Println("Authentication failed: invalid token")
                conn.WriteJSON(map[string]interface{}{"type": "auth_error", "reason": "invalid token"})
                return
            }
        case "event":
            if !authenticated {
                log.Println("Event rejected: client not authenticated")
                conn.WriteJSON(map[string]interface{}{"type":"error","reason":"not authed"})
                return
            }
            // dispatch event
            if evt, ok := msg["eventType"].(string); ok {
                payload := msg["payload"].(map[string]interface{})
                // log.Printf("Received event: %s with payload: %v\n", evt, payload)
                s.handleEvent(evt, payload)
                // ack
                if seq, ok := msg["seq"].(float64); ok {
                    conn.WriteJSON(map[string]interface{}{"type":"ack","seq":int(seq)})
                }
            }
        default:
            log.Println("unknown type", t)
        }
    }
}

func (s *Server) handleEvent(evt string, payload map[string]interface{}) {
    switch evt {
    case "mouse_move":
        dx := toFloat(payload["dx"])
        dy := toFloat(payload["dy"])
        s.injector.Move(int(dx), int(dy))
    case "mouse_click":
        btn, _ := payload["button"].(string)
        action, _ := payload["action"].(string)
        s.injector.Click(btn, action)
    case "scroll":
        dy := toFloat(payload["dy"])
        s.injector.Scroll(int(dy))
    case "key":
        key, _ := payload["key"].(string)
        action, _ := payload["action"].(string)
        // s.injector.Key(key, action)
        var modifiers []string
        if mods, ok := payload["modifiers"].([]interface{}); ok {
            for _, m := range mods {
                if modStr, isStr := m.(string); isStr {
                    modifiers = append(modifiers, modStr)
                }
            }
        }
        
        s.injector.Key(key, action, modifiers)
    default:
        log.Println("unhandled event:", evt)
    }
}

func toFloat(v interface{}) float64 {
    switch t := v.(type) {
    case float64:
        return t
    case int:
        return float64(t)
    default:
        return 0
    }
}
