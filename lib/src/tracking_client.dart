import 'dart:async';

import '../http_client.dart';

/// Tracks the entire lifecycle of a request, keeps track the number of ongoing
/// and completed requests.
class TrackingClient implements Client {
  final Client _delegate;
  final _ongoingRequests = <Future>[];
  final _ongoingContents = <Future>[];
  int _ongoingCount = 0;
  int _completedCount = 0;
  bool _isClosed = false;

  /// Creates a tracking client with a Client delegate.
  TrackingClient(this._delegate);

  /// The number of ongoing requests and content reads.
  int get ongoingCount => _ongoingCount;

  /// The number of completed requests (with input content done).
  int get completedCount => _completedCount;

  @override
  Future<Response> send(Request request) async {
    if (_isClosed) {
      throw new StateError('HTTP Client is already closed.');
    }
    _ongoingCount++;
    Future rsf;
    Future bf;
    try {
      rsf = _delegate.send(request);
      _ongoingRequests.add(rsf);
      final rs = await rsf;
      bf = rs.done;
      if (bf != null) {
        _ongoingContents.add(bf);
        // ignore: unawaited_futures
        bf.whenComplete(() {
          _ongoingContents.remove(bf);
          _ongoingCount--;
          _completedCount++;
        });
      }
      return rs;
    } finally {
      _ongoingRequests.remove(rsf);
      if (bf == null) {
        _ongoingCount--;
        _completedCount++;
      }
    }
  }

  /// Completes when the currently active requests and content reads complete.
  Future join() async {
    await Future.wait(
        _ongoingRequests.map((f) => f.whenComplete(() => null)));
    await Future.wait(
        _ongoingContents.map((f) => f.whenComplete(() => null)));
  }

  @override
  Future close({bool force = false}) async {
    _isClosed = true;
    if (!force) {
      await join();
    }
    await _delegate.close(force: force);
  }
}
