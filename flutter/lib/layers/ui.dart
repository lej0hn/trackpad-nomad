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
  bool _showBars = false;

  @override
  void initState() {
    super.initState();
    _net = widget.client;
    _input.onEvent = (e) => _net.sendEvent(e);
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final hideBars = isLandscape && !_showBars;

        return Scaffold(
          appBar: hideBars
              ? null
              : AppBar(
                  title: const Text('Trackpad Nomad'),
                  actions: [
                    if (isLandscape)
                      IconButton(
                        icon: const Icon(Icons.fullscreen),
                        tooltip: 'Hide Bars',
                        onPressed: () => setState(() => _showBars = false),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _net.disconnect();
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildTouchpadArea(),
                  _buildKeyboardArea(),
                ],
              ),
              if (hideBars)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Builder(builder: (context) {
                      return IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: () => setState(() => _showBars = true),
                      );
                    }),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: hideBars
              ? null
              : BottomNavigationBar(
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
      },
    );
  }

  Widget _buildTouchpadArea() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = isDark ? Colors.grey[850] : Colors.grey[200];
        final scrollColor = isDark ? Colors.grey[800] : Colors.grey[300];
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: surfaceColor,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        clipBehavior: Clip.antiAlias,
                        child: GestureDetector(
                          onPanUpdate: (d) => _input.handlePan(d.delta.dx, d.delta.dy),
                          child: InkWell(
                            onTap: () => _input.handleClick('left', ''),
                            child: const Center(
                              child: Text(
                                'Touch area — drag to move\nTap to click',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Scroll Area
                    Card(
                      margin: EdgeInsets.zero,
                      color: scrollColor,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      clipBehavior: Clip.antiAlias,
                      child: GestureDetector(
                        onPanUpdate: (d) => _input.handleScroll(d.delta.dy),
                        child: SizedBox(
                          width: 60,
                          child: InkWell(
                            onTap: () {}, // Just for ripple if tapped
                            child: const Center(
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  'SCROLL',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Click Buttons
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.primary,
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTapDown: (_) => _input.handleClick('left', 'down'),
                        onTapUp: (_) => _input.handleClick('left', 'up'),
                        onTapCancel: () => _input.handleClick('left', 'up'),
                        child: Container(
                          height: isLandscape ? 48 : 80,
                          alignment: Alignment.center,
                          child: Text(
                            'Left Click',
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.primaryContainer,
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTapDown: (_) => _input.handleClick('right', 'down'),
                        onTapUp: (_) => _input.handleClick('right', 'up'),
                        onTapCancel: () => _input.handleClick('right', 'up'),
                        child: Container(
                          height: isLandscape ? 48 : 80,
                          alignment: Alignment.center,
                          child: Text(
                            'Right Click',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  String _lastText = '';
  final TextEditingController _keyboardController = TextEditingController();

  Widget _buildKeyboardArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Shortcuts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _input.handleKey('f'),
                child: const Text('Maximize (F)'),
              ),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('f4', modifiers: ['alt']),
                child: const Text('Close (Alt+F4)'),
              ),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('w', modifiers: ['ctrl']),
                child: const Text('Close Tab'),
              ),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('t', modifiers: ['ctrl']),
                child: const Text('New Tab'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text("Arrows & Edit Keys", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _input.handleKey('backspace'),
                child: const Icon(Icons.backspace),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('up'),
                child: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('delete'),
                child: const Icon(Icons.delete_forever),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _input.handleKey('left'),
                child: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('down'),
                child: const Icon(Icons.arrow_downward),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('right'),
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _input.handleKey('enter'),
            icon: const Icon(Icons.keyboard_return),
            label: const Text('Enter'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          TextField(
            controller: _keyboardController,
            decoration: InputDecoration(
              hintText: 'Type here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: (s) {
              if (s.length < _lastText.length) {
                // Heuristic: Text got shorter, so user probably pressed backspace
                int diff = _lastText.length - s.length;
                for (int i = 0; i < diff; i++) {
                   _input.handleKey('backspace');
                }
              } else if (s.length > _lastText.length) {
                // Text got longer, user typed something
                 final newChars = s.substring(_lastText.length);
                 for (int i = 0; i < newChars.length; i++) {
                    _input.handleKey(newChars[i]);
                 }
              }
              _lastText = s;
            },
          ),
        ],
      ),
    );
  }
}
