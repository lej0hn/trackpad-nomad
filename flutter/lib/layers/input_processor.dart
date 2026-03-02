import 'dart:convert';

typedef EventCallback = void Function(Map<String, dynamic> evt);

class InputProcessor {
  EventCallback? onEvent;
  
  // Throttle mouse moves to max ~60Hz
  int _lastMoveTime = 0;
  final double sensitivity = 3.5;

  void handlePan(double dx, double dy) {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMoveTime < 16) return; // ~60fps Limit
    _lastMoveTime = now;

    onEvent?.call({
      'type': 'event',
      'eventType': 'mouse_move',
      'payload': {
        'dx': (dx * sensitivity).toInt(),
        'dy': (dy * sensitivity).toInt()
      },
      'seq': now,
    });
  }

  void handleClick(String button, String action) {
    onEvent?.call({
      'type': 'event',
      'eventType': 'mouse_click',
      'payload': {'button': button, 'action': action},
      'seq': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  void handleScroll(double dy) {
    onEvent?.call({
        'type': 'event',
        'eventType': 'scroll',
        'payload': {'dy': (dy * sensitivity).toInt()},
        'seq': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void handleKey(String key, {String? action, List<String>? modifiers}) {
    final payload = <String, dynamic>{'key': key};
    if (action != null) payload['action'] = action;
    if (modifiers != null) payload['modifiers'] = modifiers;

    onEvent?.call({
      'type': 'event',
      'eventType': 'key',
      'payload': payload,
      'seq': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
