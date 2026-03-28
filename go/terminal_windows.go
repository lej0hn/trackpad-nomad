//go:build windows

package main

import (
	"os"
	"golang.org/x/sys/windows"
)

func initTerminal() {
	handle := windows.Handle(os.Stdout.Fd())
	var mode uint32
	if err := windows.GetConsoleMode(handle, &mode); err == nil {
		// ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
		mode |= 0x0004
		windows.SetConsoleMode(handle, mode)
	}
}
