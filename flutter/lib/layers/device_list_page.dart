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
        MaterialPageRoute(builder: (_) => TrackpadHome(client: _net)),
      ).then((_) {
        if (mounted) {
          _loadDevices();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Connection failed: ${message ?? "Unknown error"}')),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices_other,
                          size: 80, color: Colors.grey.withValues(alpha: 128)),
                      const SizedBox(height: 16),
                      Text('No saved devices.',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Scan a QR code to pair!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final dev = _devices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.computer),
                        ),
                        title: Text(dev.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dev.host),
                        onTap: () => _net.connectSavedDevice(dev),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            await _sec.removeDevice(dev.id);
                            _loadDevices();
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final qrData = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanPage()),
          );

          if (qrData != null) {
            _net.connectFromQr(qrData, deviceName: "My PC");
          }
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }
}
