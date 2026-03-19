//go:build linux

package main

import (
	"fmt"
	"os"
	"os/exec"

	"golang.org/x/term"
)

func initTerminal() {
	// Check if stdout is attached to a terminal
	if term.IsTerminal(int(os.Stdout.Fd())) || term.IsTerminal(int(os.Stdin.Fd())) {
		return // we are running in a terminal
	}

	// We are not in a terminal. Try to find our executable.
	executable, err := os.Executable()
	if err != nil {
		fmt.Println("Error getting executable path:", err)
		return
	}

	// List of common Linux terminal emulators and their execute flags.
	terminals := [][]string{
		{"x-terminal-emulator", "-e"},
		{"gnome-terminal", "--"},
		{"konsole", "-e"},
		{"xfce4-terminal", "-x"},
		{"alacritty", "-e"},
		{"kitty", "-e"},
		{"xterm", "-e"},
	}

	for _, termArgs := range terminals {
		termBin := termArgs[0]
		path, err := exec.LookPath(termBin)
		if err == nil {
			var args []string
			if len(termArgs) > 1 {
				args = append(args, termArgs[1:]...)
			}
			args = append(args, executable)

			// Pass along any arguments the user may have provided (usually empty if double clicked)
			args = append(args, os.Args[1:]...)

			cmd := exec.Command(path, args...)
			
			// Detach the child process so it survives
			if err := cmd.Start(); err != nil {
				continue
			}

			// Successfully spawned a terminal carrying this server, exit this background process
			os.Exit(0)
		}
	}
}
