package server

import (
    "fmt"
    "os"

    qrcode "github.com/mdp/qrterminal/v3"
)

func PrintQR(payload string) {
    fmt.Println("Pairing QR:")
    qrcode.Generate(payload, qrcode.L, os.Stdout)
}
