import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Device {
  final String id;
  final String name;
  final String host;
  final String refreshToken;

  Device({
    required this.id,
    required this.name,
    required this.host,
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'refreshToken': refreshToken,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'],
        name: json['name'] ?? '',
        host: json['host'],
        refreshToken: json['refreshToken'],
      );
}

class Security {
  final _storage = const FlutterSecureStorage();

  static const _keyDevices = 'devicesV2';

  Future<List<Device>> getDevices() async {
    final raw = await _storage.read(key: _keyDevices);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Device.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDevice(Device device) async {
    final devices = await getDevices();
    final index = devices.indexWhere((d) => d.id == device.id || d.host == device.host);
    if (index != -1) {
      devices[index] = device;
    } else {
      devices.add(device);
    }
    await _storage.write(key: _keyDevices, value: jsonEncode(devices.map((e) => e.toJson()).toList()));
  }

  Future<void> removeDevice(String id) async {
    final devices = await getDevices();
    devices.removeWhere((d) => d.id == id);
    await _storage.write(key: _keyDevices, value: jsonEncode(devices.map((e) => e.toJson()).toList()));
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
