class TimeSyncService {
  static final TimeSyncService instance = TimeSyncService._internal();

  int _offsetMs = 0;

  TimeSyncService._internal();

  /// Updates the server time and calculates the offset compared to the local device time.
  void updateServerTime(int serverTimeMs) {
    final localTimeMs = DateTime.now().millisecondsSinceEpoch;
    _offsetMs = serverTimeMs - localTimeMs;
  }

  /// Returns the synchronized `DateTime.now()` accounting for the server offset.
  DateTime now() {
    return DateTime.now().add(Duration(milliseconds: _offsetMs));
  }
}
