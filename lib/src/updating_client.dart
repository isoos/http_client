import 'dart:async';

import 'package:meta/meta.dart';

import '../http_client.dart';
import 'tracking_client.dart';

/// Creates a HTTP client asynchronously.
typedef Future<Client> CreateClientFn();

/// Automatically updates the underlying client after the specified use limits.
class UpdatingClient implements Client {
  final CreateClientFn _createClientFn;
  final int _requestLimit;
  final Duration _timeLimit;

  final _pastClients = <_Client>[];
  _Client _current;
  Completer _nextCompleter;
  bool _isClosing = false;

  ///
  UpdatingClient({
    @required CreateClientFn createClientFn,
    int requestLimit = 1000,
    Duration timeLimit = const Duration(hours: 1),
  })  : _createClientFn = createClientFn,
        _requestLimit = requestLimit,
        _timeLimit = timeLimit;

  @override
  Future<Response> send(Request request) {
    return withClient((client) => client.send(request));
  }

  /// Runs a function with a [TrackingClient] as parameter and handles
  /// invalidation on exceptions.
  ///
  /// The client remains the same until the function completes.
  Future<R> withClient<R>(
    Future<R> fn(TrackingClient client), {
    bool invalidateOnError = false,
    bool forceCloseOnError = false,
  }) async {
    await _cleanupPastClients(false);
    final client = await _allocate();
    try {
      return await fn(client._client);
    } catch (_) {
      if (invalidateOnError || forceCloseOnError) {
        client._forceClose = forceCloseOnError;
        if (_current == client) {
          _current = null;
          _pastClients.add(client);
        }
      }
      rethrow;
    } finally {
      await _release(client);
      await _cleanupPastClients(false);
    }
  }

  @override
  Future close({bool force = false}) async {
    _isClosing = true;
    expireCurrent();
    await _cleanupPastClients(force);
    await _current?._client?.close(force: force);
  }

  Future _cleanupPastClients(bool force) async {
    final futures = _pastClients
        .map((c) => c._client.close(force: force || c._forceClose))
        .map((f) => f.whenComplete(() => null))
        .toList();
    await Future.wait(futures);
  }

  Future<_Client> _allocate() async {
    if (_isClosing) {
      throw StateError('HTTP Client closing.');
    }
    // expire if needed
    if (_current != null && _current.isExpired(_requestLimit, _timeLimit)) {
      expireCurrent();
    }
    // wait for ongoing creation
    if (_nextCompleter != null) {
      await _nextCompleter.future;
    }
    // return if available
    if (_current != null) {
      _current._useCount++;
      return _current;
    }
    // create new
    _nextCompleter = Completer();
    try {
      final client = await _createClientFn();
      final trackingClient =
          client is TrackingClient ? client : TrackingClient(client);
      expireCurrent();
      _current = _Client(trackingClient);
      _current._useCount++;
      _nextCompleter.complete();
      return _current;
    } finally {
      _nextCompleter = null;
    }
  }

  /// Marks the currently active client as expired, next calls should trigger a
  /// new client creation.
  void expireCurrent({bool force = false}) {
    if (_current != null) {
      _current._forceClose = force;
      _pastClients.add(_current);
      _current = null;
    }
  }

  Future _release(_Client client) async {
    client._useCount--;
  }
}

class _Client {
  final TrackingClient _client;
  final _created = DateTime.now();
  int _useCount = 0;
  bool _forceClose = false;

  _Client(this._client);

  int get requestCount => _client.ongoingCount + _client.completedCount;

  bool isExpired(int requestLimit, Duration timeLimit) {
    if (requestCount > requestLimit) return true;
    final now = DateTime.now();
    final diff = now.difference(_created);
    if (diff > timeLimit) return true;
    return false;
  }
}
