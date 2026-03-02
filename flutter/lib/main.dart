import 'package:flutter/material.dart';
import 'layers/device_list_page.dart';

void main() {
  runApp(const TouchpadApp());
}

class TouchpadApp extends StatelessWidget {
  const TouchpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DeviceListPage(),
    );
  }
}
