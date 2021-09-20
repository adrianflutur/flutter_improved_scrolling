/// Throttle some action by a specified amount of milliseconds
class Throttler {
  /// Throttle value
  Throttler(this._throttleTimeMs);

  final int _throttleTimeMs;
  int? _lastRunTimeMs;

  /// Run the function which needs to be throttled
  void run(void Function() action) {
    if (_lastRunTimeMs == null) {
      action();
      _lastRunTimeMs = DateTime.now().millisecondsSinceEpoch;
    } else {
      if (DateTime.now().millisecondsSinceEpoch - _lastRunTimeMs! >
          _throttleTimeMs) {
        action();
        _lastRunTimeMs = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }
}
