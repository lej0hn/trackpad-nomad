package main

import (
    "flag"
    "fmt"
    "log"
    "net/http"
    "os"

    "touchpad2/server"
)

func main() {
    var addr string
    var port string
    flag.StringVar(&addr, "addr", "0.0.0.0:8080", "listen address")
    flag.StringVar(&port, "port", "8080", "public port for QR pairing")
    flag.Parse()

    // Generate a session token and create server instance
    srv := server.NewServer()

    // Print pairing QR and info
    srv.PrintPairingInfo(port)

    http.HandleFunc("/ws", srv.HandleWS)

    fmt.Printf("Listening on %s\n", addr)
    if err := http.ListenAndServe(addr, nil); err != nil {
        log.Println("ListenAndServe:", err)
        os.Exit(1)
    }
}
