import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'network.dart';
import 'qr_scan_page.dart';
import 'input_processor.dart';
import 'security.dart';

class TrackpadHome extends StatefulWidget {
  final NetworkClient client;
  const TrackpadHome({super.key, required this.client});

  @override
  State<TrackpadHome> createState() => _TrackpadHomeState();
}

class _TrackpadHomeState extends State<TrackpadHome> {
  late final NetworkClient _net;
  final InputProcessor _input = InputProcessor();

  int _selectedIndex = 0;
  bool _showBars = false;

  final Map<int, Offset> _activePointers = {};
  int _maxPointers = 0;
  bool _hasMoved = false;
  double _totalMovement = 0.0;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _net = widget.client;
    _input.onEvent = (e) => _net.sendEvent(e);
    _net.onClipboardReceived = (text) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied from PC to phone clipboard')),
        );
      }
    };
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
                  _buildTrackpadArea(),
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
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh
                              .withOpacity(0.8),
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
                      label: 'Trackpad',
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

  void _recalculateFocalPoint() {
    if (_activePointers.isEmpty) {
      _lastFocalPoint = null;
      return;
    }
    double x = 0;
    double y = 0;
    for (final pos in _activePointers.values) {
      x += pos.dx;
      y += pos.dy;
    }
    _lastFocalPoint =
        Offset(x / _activePointers.length, y / _activePointers.length);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length > _maxPointers) {
      _maxPointers = _activePointers.length;
    }
    _recalculateFocalPoint();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointers.containsKey(event.pointer)) {
      _activePointers[event.pointer] = event.position;
      final oldFocal = _lastFocalPoint;
      _recalculateFocalPoint();

      if (oldFocal != null && _lastFocalPoint != null) {
        final delta = _lastFocalPoint! - oldFocal;
        _totalMovement += delta.distance;
        if (_totalMovement > 2.5) {
          _hasMoved = true;
        }

        if (_activePointers.length == 1) {
          _input.handlePan(event.delta.dx, event.delta.dy);
        } else if (_activePointers.length >= 2) {
          _input.handleScroll(delta.dy);
        }
      }
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _recalculateFocalPoint();

    if (_activePointers.isEmpty) {
      if (!_hasMoved) {
        if (_maxPointers == 1) {
          _input.handleClick('left', '');
        } else if (_maxPointers == 3) {
          _input.handleClick('right', '');
        }
      }
      _maxPointers = 0;
      _hasMoved = false;
      _totalMovement = 0.0;
      _lastFocalPoint = null;
    }
  }

  Widget _buildTrackpadArea() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = isDark ? Colors.grey[850] : Colors.grey[200];
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
                        child: Listener(
                          onPointerDown: _handlePointerDown,
                          onPointerMove: _handlePointerMove,
                          onPointerUp: _handlePointerUp,
                          onPointerCancel: _handlePointerUp,
                          behavior: HitTestBehavior.opaque,
                          child: const Center(
                            child: Text(
                              'Touch area — 1-finger move, 2-finger scroll\nTap: 1-finger Left Click, 3-finger Right Click',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.grey),
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
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
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
                            style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
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
          const Text("Clipboard Sync",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('From PC'),
                  onPressed: () {
                    _net.requestClipboard();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Requesting PC clipboard...')));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('To PC'),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null &&
                        data.text != null &&
                        data.text!.isNotEmpty) {
                      _net.sendClipboard(data.text!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sent phone clipboard to PC')));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Phone clipboard is empty')));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text("Shortcuts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _input.handleKey('c', modifiers: ['ctrl']),
                child: const Text('Copy (Ctrl+C)'),
              ),
              FilledButton.tonal(
                onPressed: () => _input.handleKey('v', modifiers: ['ctrl']),
                child: const Text('Paste (Ctrl+V)'),
              ),
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
          const Text("Arrows & Edit Keys",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
