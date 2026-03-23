import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'security.dart';

class NetworkClient {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;

  final Security _sec = Security();
  final Logger _logger = Logger();

  void Function(bool success, String? message)? onAuthStatus;
  void Function(String text)? onClipboardReceived;

  bool get isConnected => _ch != null;

  String _generateDeviceId() {
    final r = Random();
    return List.generate(
        16, (i) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> connectFromQr(String qrData,
      {String deviceName = "Mobile Device"}) async {
    try {
      _logger.i("QR Data Scanned: $qrData");
      final Map<String, dynamic> data = jsonDecode(qrData);

      final host = data['host'];
      final token = data['token'];

      if (host == null || token == null) {
        throw Exception('Invalid QR format. Missing host or token');
      }

      await disconnect();

      final uri = Uri.parse("ws://$host/ws");
      _logger.i("Connecting to $uri");

      _ch = WebSocketChannel.connect(uri);

      // Check if we already have a device saved for this host
      // so we can reuse our device ID instead of creating a new one.
      final existingDevices = await _sec.getDevices();
      String deviceId = _generateDeviceId();
      try {
        final existing = existingDevices.firstWhere((d) => d.host == host);
        deviceId = existing.id;
        _logger.i("Reusing existing device ID $deviceId for host $host");
      } catch (_) {}

      _sub = _ch!.stream.listen(
        (msg) => _handleMessage(msg, host, deviceId, deviceName),
        onDone: () {
          _logger.w("Connection closed");
          _ch = null;
        },
        onError: (e) {
          _logger.e("WebSocket error: $e");
        },
      );

      _logger.i("Connected to server, sending auth token...");

      _ch!.sink.add(jsonEncode({
        'type': 'auth',
        'token': token,
        'device_id': deviceId,
        'device_name': deviceName,
      }));
    } catch (e) {
      _logger.e("Error connecting", error: e);
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
      }, onError: (e) {
        _logger.e("WS Error", error: e);
      });

      _ch!.sink.add(jsonEncode({
        'type': 'auth',
        'device_id': device.id,
        'refresh_token': device.refreshToken,
      }));
    } catch (e) {
      _logger.e("Connect error", error: e);
      rethrow;
    }
  }

  void _handleMessage(
      dynamic msg, String host, String deviceId, String deviceName) {
    try {
      final Map<String, dynamic> data = jsonDecode(msg);
      final type = data['type'];

      if (type == 'auth_ok') {
        _logger.i("Auth success");

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
        _logger.w("Auth failed: ${data['reason']}");
        onAuthStatus?.call(false, data['reason']);
        disconnect();
      } else if (type == 'clipboard_data') {
        final text = data['text'];
        if (text is String && text.isNotEmpty) {
          onClipboardReceived?.call(text);
        }
      }
    } catch (e) {
      _logger.e("Handle message error", error: e);
    }
  }

  void sendEvent(Map<String, dynamic> evt) {
    if (_ch == null) return;
    _ch!.sink.add(jsonEncode(evt));
  }

  void sendClipboard(String text) {
    sendEvent({
      'type': 'event',
      'eventType': 'clipboard_set',
      'payload': {'text': text},
      'seq': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void requestClipboard() {
    sendEvent({
      'type': 'event',
      'eventType': 'clipboard_get',
      'payload': {},
      'seq': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _ch?.sink.close();
    _ch = null;
    _sub = null;
  }
}
