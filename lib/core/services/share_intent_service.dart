import 'dart:async';

/// Desktop stub for ShareIntentService.
/// On desktop (macOS/Windows/Linux) there is no share intent mechanism,
/// so all methods are no-ops and streams emit nothing.
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  final _controller = StreamController<List<dynamic>>.broadcast();

  Stream<List<dynamic>> get pendingFilesStream => _controller.stream;
  List<dynamic>? get initialFiles => null;

  void init() {}
  void clearFiles() {}
  void dispose() {
    _controller.close();
  }
}
