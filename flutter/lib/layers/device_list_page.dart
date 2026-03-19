import 'package:flutter/material.dart';
import 'network.dart';
import 'security.dart';
import 'ui.dart';
import 'qr_scan_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final Security _sec = Security();
  final NetworkClient _net = NetworkClient();
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _net.onAuthStatus = _handleAuthStatus;
  }

  Future<void> _loadDevices() async {
    final devs = await _sec.getDevices();
    setState(() {
      _devices = devs;
      _isLoading = false;
    });
  }

  void _handleAuthStatus(bool success, String? message) {
    if (!mounted) return;
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TouchpadHome(client: _net)),
      ).then((_) {
        if (mounted) {
          _loadDevices();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${message ?? "Unknown error"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Devices')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Center(child: Text('No saved devices. Scan a QR code to pair!'))
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final dev = _devices[index];
                    return ListTile(
                      leading: const Icon(Icons.computer),
                      title: Text(dev.name),
                      subtitle: Text(dev.host),
                      onTap: () => _net.connectSavedDevice(dev),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _sec.removeDevice(dev.id);
                          _loadDevices();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final qrData = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanPage()),
          );

          if (qrData != null) {
            _net.connectFromQr(qrData, deviceName: "My PC");
          }
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
