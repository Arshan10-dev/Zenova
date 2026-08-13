import 'dart:async';

/// Delays calling [action] until [delay] has passed without a new call —
/// used so search fields don't re-filter a 10,000-song library on every
/// keystroke.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
