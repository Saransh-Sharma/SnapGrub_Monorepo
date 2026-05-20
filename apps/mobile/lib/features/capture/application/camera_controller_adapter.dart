class CameraControllerAdapter {
  bool _initialized = false;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _initialized;

  Future<bool> requestPermission() async {
    _hasPermission = true;
    return _hasPermission;
  }

  Future<void> initialize() async {
    if (!_hasPermission) return;
    _initialized = true;
  }

  Future<void> pause() async {
    if (_initialized) _initialized = false;
  }

  Future<void> resume() async {
    if (_hasPermission) _initialized = true;
  }

  Future<void> dispose() async {
    _initialized = false;
  }
}
