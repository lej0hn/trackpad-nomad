package server

import (
    "log"
    "github.com/go-vgo/robotgo"
)

// InputInjector abstracts OS-specific input injection.
type InputInjector interface {
    Move(dx, dy int)
    Click(button, action string)
    Scroll(dy int)
    Key(key, action string, modifiers []string)
    WriteClipboard(text string)
    ReadClipboard() string
}

// LoggerInjector is a simple injector that logs incoming events.
type LoggerInjector struct{}

func (l *LoggerInjector) Move(dx, dy int) {
    log.Printf("Move: dx=%d dy=%d\n", dx, dy)
}

func (l *LoggerInjector) Click(button, action string) {
    log.Printf("Click: button=%s action=%s\n", button, action)
}

func (l *LoggerInjector) Scroll(dy int) {
    log.Printf("Scroll: dy=%d\n", dy)
}

func (l *LoggerInjector) Key(key, action string, modifiers []string) {
    log.Printf("Key: key=%s action=%s modifiers=%v\n", key, action, modifiers)
}

func (l *LoggerInjector) WriteClipboard(text string) {
    log.Printf("WriteClipboard: %s\n", text)
}

func (l *LoggerInjector) ReadClipboard() string {
    log.Printf("ReadClipboard\n")
    return ""
}

// RobotGoInjector uses go-vgo/robotgo to control OS input
type RobotGoInjector struct{}

func (r *RobotGoInjector) Move(dx, dy int) {
    // robotgo.MoveRelative is used to move by offset
    robotgo.MoveRelative(dx, dy)
}

func (r *RobotGoInjector) Click(button, action string) {
    // default to left if invalid
    if button != "left" && button != "right" && button != "middle" {
        button = "left"
    }

    if action == "down" {
        robotgo.Toggle(button, "down")
    } else if action == "up" {
        robotgo.Toggle(button, "up")
    } else {
        // assume a single click if action is empty or invalid
        robotgo.Click(button)
    }
}

func (r *RobotGoInjector) Scroll(dy int) {
    // robotgo Scroll(x, y direction). Passing dy as the y-coordinate.
    robotgo.Scroll(0, dy)
}

func (r *RobotGoInjector) Key(key, action string, modifiers []string) {
    // Convert []string to []interface{} for robotgo variadic functions
    var args []interface{}
    for _, m := range modifiers {
        args = append(args, m)
    }

    // Toggle keys depending on action
    if action == "down" {
        for _, m := range modifiers {
            robotgo.KeyDown(m)
        }
        robotgo.KeyDown(key)
    } else if action == "up" {
        robotgo.KeyUp(key)
        for _, m := range modifiers {
            robotgo.KeyUp(m)
        }
    } else {
        if len(args) > 0 {
            robotgo.KeyTap(key, args...)
        } else {
            robotgo.KeyTap(key)
        }
    }
}

func (r *RobotGoInjector) WriteClipboard(text string) {
    robotgo.WriteAll(text)
}

func (r *RobotGoInjector) ReadClipboard() string {
    text, _ := robotgo.ReadAll()
    return text
}
