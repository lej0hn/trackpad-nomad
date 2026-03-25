//go:build windows

package main

import (
	"os"
	"syscall"
)

func initTerminal() {
	handle := syscall.Handle(os.Stdout.Fd())
	var mode uint32
	if err := syscall.GetConsoleMode(handle, &mode); err == nil {
		// ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
		mode |= 0x0004
		syscall.SetConsoleMode(handle, mode)
	}
}
