package server

import (
    "crypto/rand"
    "encoding/base64"
)

func GenerateToken() string {
    b := make([]byte, 32)
    _, err := rand.Read(b)
    if err != nil {
        // fallback (should not happen)
        return base64.RawURLEncoding.EncodeToString([]byte("fallback-token"))
    }
    return base64.RawURLEncoding.EncodeToString(b)
}
