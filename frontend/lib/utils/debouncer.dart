import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class that adds delay to operations that would otherwise happen too frequently
/// (e.g. search-as-you-type, which would otherwise make lots of API calls).
class Debouncer {
  /// The length of time to wait after the user stops typing
  final Duration delay;

  /// The timer that is started when the user types
  Timer? _timer;

  /// Creates a new debouncer with the specified delay
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Call the provided action after waiting for the delay
  void run(VoidCallback action) {
    // Cancel the previous timer
    _timer?.cancel();
    // Start a new timer
    _timer = Timer(delay, action);
  }

  /// Cancel any active timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
