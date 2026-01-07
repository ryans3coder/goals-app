class VictoryGate {
  bool _hasTriggered = false;

  bool tryOpen() {
    if (_hasTriggered) {
      return false;
    }
    _hasTriggered = true;
    return true;
  }

  void reset() {
    _hasTriggered = false;
  }
}
