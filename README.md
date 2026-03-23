<h1 align="center">
  🌐 Trackpad Nomad 🖱️
</h1>

<p align="center">
  <strong>Turn your smartphone into a fast, secure, and wireless trackpad & keyboard for your computer.</strong>
</p>

<p align="center">
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/lej0hn/trackpad-nomad?style=for-the-badge">
  <img alt="Flutter App" src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white">
  <img alt="Go Backend" src="https://img.shields.io/badge/Go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white">
</p>

---

## 🚀 What is Trackpad Nomad?

Ever been sitting away from your desk, trying to control a movie or presentation on your computer, but didn't have a wireless mouse? **Trackpad Nomad** solves this by transforming your smartphone into a remote, responsive, and cross-platform input device over your local WiFi network. 

No cables, no dongles, just seamless control.

## ✨ Features

- 🖱️ **Smooth Trackpad Emulation**: Move the cursor, click, right-click, and scroll with the precision of a native trackpad.
- ⌨️ **Remote Keyboard**: Type on your computer effortlessly from your phone's native keyboard.
- 🔒 **Secure Connection**: Uses short-lived, single-use QR tokens for easy, secure pairing.
- 📱 **Saved Devices Pipeline**: Reconnect to paired computers with a single tap using long-lived secure refresh tokens.
- ⚡ **Cross-Platform Server**: Blazing-fast backend written in Go, supporting **Windows, macOS, and Linux**.
- 🚀 **Beautiful Client App**: A fast, responsive, and native-feeling mobile app built with Flutter.

---

## 🛠️ Getting Started (The Easy Way)
You don't need to know how to code to use Trackpad Nomad. Just download the ready-to-go binaries!

### Step 1: Download the App
Go to the [Releases page](https://github.com/lej0hn/trackpad-nomad/releases) and download the **Android APK** (`app-release.apk`) to your phone and install it.

### Step 2: Download the Server
From the same [Releases page](https://github.com/lej0hn/trackpad-nomad/releases), download the server executable for your computer's OS:
- **Windows**: `trackpad-server-windows-amd64.exe`
- **macOS (Intel/Apple Silicon)**: `trackpad-server-macos-*`
- **Linux**: `trackpad-server-linux-amd64`

### Step 3: Run and Pair!
1. Run the server executable on your computer. A QR code will instantly appear in your terminal.
2. Ensure both your phone and computer are on the **same WiFi network**.
3. Open the **Trackpad Nomad** app on your phone.
4. Scan the QR code, and you are instantly connected!

*Tip: The next time you want to connect, just open the app and tap your computer under "Saved Devices" to reconnect automatically!*

---

## 👨‍💻 Getting Started (For Developers)

Want to build from source, contribute, or tweak things? Here's how you can get everything running locally.

### Prerequisites
- **Flutter SDK** (for the mobile client)
- **Go 1.24+** (for the backend server)
- *(Linux only)* C bindings for OS inputs: `sudo apt-get install libx11-dev libxext-dev libxkbcommon-dev libxkbcommon-x11-dev libxtst-dev`

### Running the Server
```bash
cd go
# Install Go dependencies
go mod tidy 
# Run the Go server directly
go run main.go
```
The server will start listening on your local network and display a pairing QR code in the terminal.

### Running the Flutter App
```bash
cd flutter
# Get Flutter dependencies
flutter pub get
# Run the app on an emulator or physical device
flutter run
```

---

## 🏗️ Architecture Stack
- **Frontend App**: Flutter 💙 (Dart)
- **Backend Server**: Go 🦫 (using robotgo for OS-level HID emulation)
- **Transport Layer**: Real-time WebSockets
- **Authentication**: Custom hash-based refresh tokens & short-lived QR pairing

## 📄 License
This project is licensed under the conditions established in the `LICENSE` file.
