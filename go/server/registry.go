package server

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"log"
	"os"
	"sync"
	"time"
)

// Device represents a trusted mobile client.
type Device struct {
	ID                string    `json:"id"`
	Name              string    `json:"name"`
	HashedRefreshToken string    `json:"hashed_refresh_token"`
	CreatedAt         time.Time `json:"created_at"`
	LastSeen          time.Time `json:"last_seen"`
}

// DeviceRegistry manages the persistence of trusted devices.
type DeviceRegistry struct {
	filePath string
	devices  map[string]Device // device_id -> Device
	mu       sync.RWMutex
}

// NewDeviceRegistry creates or loads a device registry from the given file.
func NewDeviceRegistry(filePath string) *DeviceRegistry {
	reg := &DeviceRegistry{
		filePath: filePath,
		devices:  make(map[string]Device),
	}
	reg.load()
	return reg
}

// load reads the registry from disk if it exists.
func (r *DeviceRegistry) load() {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.filePath)
	if err != nil {
		if !os.IsNotExist(err) {
			log.Printf("Failed to read device registry %s: %v\n", r.filePath, err)
		}
		return
	}

	if err := json.Unmarshal(data, &r.devices); err != nil {
		log.Printf("Failed to parse device registry: %v\n", err)
	}
}

// save writes the current registry to disk.
func (r *DeviceRegistry) save() {
	data, err := json.MarshalIndent(r.devices, "", "  ")
	if err != nil {
		log.Printf("Failed to marshal device registry: %v\n", err)
		return
	}

	if err := os.WriteFile(r.filePath, data, 0600); err != nil {
		log.Printf("Failed to write device registry: %v\n", err)
	}
}

// RegisterDevice adds or updates a device using a raw refresh token.
// The raw token is hashed before being saved.
func (r *DeviceRegistry) RegisterDevice(id, name, rawRefreshToken string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	hashed := r.hashToken(rawRefreshToken)

	dev, exists := r.devices[id]
	if !exists {
		dev = Device{
			ID:        id,
			Name:      name,
			CreatedAt: time.Now(),
		}
	} else if name != "" {
		dev.Name = name // Update name if provided
	}

	dev.HashedRefreshToken = hashed
	dev.LastSeen = time.Now()
	
	r.devices[id] = dev
	r.save()
}

// ValidateReconnection checks if the provided raw refresh token is valid for the device ID.
func (r *DeviceRegistry) ValidateReconnection(id, rawRefreshToken string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	dev, exists := r.devices[id]
	if !exists {
		return false
	}

	hashed := r.hashToken(rawRefreshToken)
	if dev.HashedRefreshToken == hashed {
		// Update last seen
		dev.LastSeen = time.Now()
		r.devices[id] = dev
		
		// Run save asynchronously to avoid blocking connection
		go func() {
			r.mu.Lock()
			r.save()
			r.mu.Unlock()
		}()
		
		return true
	}

	return false
}

// RemoveDevice deletes a device from the registry.
func (r *DeviceRegistry) RemoveDevice(id string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.devices, id)
	r.save()
}

// hashToken creates a SHA-256 hash of the token for secure storage.
func (r *DeviceRegistry) hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}
