import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'security.dart';

class NetworkClient {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;

  final Security _sec = Security();
  
  void Function(bool success, String? message)? onAuthStatus;

  bool get isConnected => _ch != null;

  String _generateDeviceId() {
    final r = Random();
    return List.generate(16, (i) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> connectFromQr(String qrData, {String deviceName = "Mobile Device"}) async {
    try {
      print("QR Data Scanned: $qrData");
      final Map<String, dynamic> data = jsonDecode(qrData);

      final host = data['host'];
      final token = data['token'];

      if (host == null || token == null) {
        throw Exception('Invalid QR format. Missing host or token');
      }

      await disconnect(); 

      final uri = Uri.parse("ws://$host/ws");
      print("Connecting to $uri");

      _ch = WebSocketChannel.connect(uri);

      // Check if we already have a device saved for this host
      // so we can reuse our device ID instead of creating a new one.
      final existingDevices = await _sec.getDevices();
      String deviceId = _generateDeviceId();
      try {
        final existing = existingDevices.firstWhere((d) => d.host == host);
        deviceId = existing.id;
        print("Reusing existing device ID $deviceId for host $host");
      } catch (_) {}

      _sub = _ch!.stream.listen(
        (msg) => _handleMessage(msg, host, deviceId, deviceName),
        onDone: () {
          print("Connection closed");
          _ch = null;
        },
        onError: (e) {
          print("WebSocket error: $e");
        },
      );
      
      print("Connected to server, sending auth token...");

      _ch!.sink.add(jsonEncode({
        'type': 'auth',
        'token': token,
        'device_id': deviceId,
        'device_name': deviceName,
      }));
      
    } catch (e) {
      print("Error connecting: $e");
      rethrow;
    }
  }

  Future<void> connectSavedDevice(Device device) async {
    try {
      await disconnect();
      
      final uri = Uri.parse("ws://${device.host}/ws");
      _ch = WebSocketChannel.connect(uri);

      _sub = _ch!.stream.listen(
        (msg) => _handleMessage(msg, device.host, device.id, device.name),
        onDone: () {
           _ch = null;
        },
        onError: (e) {
          print("WS Error: $e");
        }
      );

      _ch!.sink.add(jsonEncode({
        'type': 'auth',
        'device_id': device.id,
        'refresh_token': device.refreshToken,
      }));

    } catch (e) {
      print("Connect error: $e");
      rethrow;
    }
  }

  void _handleMessage(dynamic msg, String host, String deviceId, String deviceName) {
    try {
      final Map<String, dynamic> data = jsonDecode(msg);
      final type = data['type'];

      if (type == 'auth_ok') {
        print("Auth success");
        
        // If server sent back device info (on initial pairing), save it.
        if (data['device'] != null) {
          final devInfo = data['device'];
          final newDevice = Device(
            id: devInfo['id'] ?? deviceId,
            name: devInfo['name'] ?? deviceName,
            host: host,
            refreshToken: devInfo['refresh_token'],
          );
          _sec.saveDevice(newDevice);
        }
        
        onAuthStatus?.call(true, null);
      } else if (type == 'auth_error') {
        print("Auth failed: ${data['reason']}");
        onAuthStatus?.call(false, data['reason']);
        disconnect();
      }
    } catch (e) {
      print("Handle message error: $e");
    }
  }

  void sendEvent(Map<String, dynamic> evt) {
    if (_ch == null) return;
    _ch!.sink.add(jsonEncode(evt));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _ch?.sink.close();
    _ch = null;
    _sub = null;
  }
}
