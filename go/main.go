package main

import (
	"bufio"
    "flag"
    "fmt"
    "log"
    "net/http"
    "os"

    "trackpadNomad/server"
)

func main() {
	// catch panics and wait for input to keep terminal open
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("\nFATAL ERROR: %v\n", r)
			fmt.Println("Press Enter to exit...")
			bufio.NewReader(os.Stdin).ReadBytes('\n')
			os.Exit(1)
		}
	}()

	initTerminal()
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
		fmt.Println("\nPress Enter to exit...")
		bufio.NewReader(os.Stdin).ReadBytes('\n')
        os.Exit(1)
    }
}
