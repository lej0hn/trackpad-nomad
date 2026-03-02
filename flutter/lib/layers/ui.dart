import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'network.dart';
import 'qr_scan_page.dart';
import 'input_processor.dart';
import 'security.dart';

class TouchpadHome extends StatefulWidget {
  final NetworkClient client;
  const TouchpadHome({super.key, required this.client});

  @override
  State<TouchpadHome> createState() => _TouchpadHomeState();
}

class _TouchpadHomeState extends State<TouchpadHome> {
  late final NetworkClient _net;
  final InputProcessor _input = InputProcessor();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _net = widget.client;
    _input.onEvent = (e) => _net.sendEvent(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TouchPad2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _net.disconnect();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTouchpadArea(),
          _buildKeyboardArea(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app),
            label: 'Touchpad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard),
            label: 'Keyboard',
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpadArea() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (d) => _input.handlePan(d.delta.dx, d.delta.dy),
                  onTap: () => _input.handleClick('left', ''),
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('Touch area — drag to move\nTap to click')),
                  ),
                ),
              ),
              // Scroll Area
              GestureDetector(
                onPanUpdate: (d) => _input.handleScroll(d.delta.dy),
                child: Container(
                  width: 60,
                  color: Colors.grey[300],
                  child: const Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text('SCROLL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Click Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => _input.handleClick('left', 'down'),
                onTapUp: (_) => _input.handleClick('left', 'up'),
                child: Container(
                  height: 80,
                  color: Colors.blue[300],
                  child: const Center(child: Text('Left Click', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => _input.handleClick('right', 'down'),
                onTapUp: (_) => _input.handleClick('right', 'up'),
                child: Container(
                  height: 80,
                  color: Colors.blue[400],
                  child: const Center(child: Text('Right Click', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildKeyboardArea() {
    final TextEditingController ctl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Shortcuts", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _input.handleKey('f'),
                child: const Text('Maximize (F)'),
              ),
              ElevatedButton(
                onPressed: () => _input.handleKey('f4', modifiers: ['alt']),
                child: const Text('Close (Alt+F4)'),
              ),
              ElevatedButton(
                onPressed: () => _input.handleKey('w', modifiers: ['ctrl']),
                child: const Text('Close Tab'),
              ),
              ElevatedButton(
                onPressed: () => _input.handleKey('t', modifiers: ['ctrl']),
                child: const Text('New Tab'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text("Arrows & Edit Keys", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _input.handleKey('backspace'),
                child: const Icon(Icons.backspace),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _input.handleKey('up'),
                child: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _input.handleKey('delete'),
                child: const Icon(Icons.delete_forever),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _input.handleKey('left'),
                child: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _input.handleKey('down'),
                child: const Icon(Icons.arrow_downward),
              ),
              const SizedBox(width: 10),
               ElevatedButton(
                onPressed: () => _input.handleKey('right'),
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          const Spacer(),
          const Divider(),
          TextField(
            controller: ctl,
            decoration: const InputDecoration(
                hintText: 'Type here...',
                border: OutlineInputBorder()
            ),
            onChanged: (s) {
              if (s.isNotEmpty) {
                final last = s.substring(s.length - 1);
                _input.handleKey(last);
              }
            },
          ),
        ],
      ),
    );
  }
}
