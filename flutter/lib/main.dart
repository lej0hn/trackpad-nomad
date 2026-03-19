import 'package:flutter/material.dart';
import 'layers/device_list_page.dart';

void main() {
  runApp(const TouchpadApp());
}

class TouchpadApp extends StatelessWidget {
  const TouchpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const DeviceListPage(),
    );
  }
}
