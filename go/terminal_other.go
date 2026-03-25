//go:build !linux && !windows

package main

func initTerminal() {
	// For Windows and macOS, we rely on default OS behavior when double-clicking executables.
	// Windows natively opens generic Console windows for programs built without `-H=windowsgui`.
	// macOS app bundles/scripts or raw executables in Finder have their own handler approaches.
}
