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

  /// Runs a function with a [Client] as parameter (which that remains the same
  /// until the function completes.
  Future<R> withClient<R>(Future<R> fn(Client client)) async {
    final client = await _allocate();
    try {
      return await fn(client._client);
    } finally {
      await _release(client);
    }
  }

  @override
  Future close({bool force = false}) async {
    _isClosing = true;
    final futures =
        _pastClients.map((c) => c._client.close(force: force)).toList();
    futures.add(_current?._client?.close(force: force));
    await Future.wait(futures);
  }

  Future<_Client> _allocate() async {
    if (_isClosing) {
      throw StateError('HTTP Client closing.');
    }
    // cleanup past clients
    while (_pastClients.isNotEmpty && _pastClients.last._useCount == 0) {
      final client = _pastClients.removeLast();
      await client._client.close();
    }
    // expire if needed
    if (_current != null && _current.isExpired(_requestLimit, _timeLimit)) {
      _pastClients.add(_current);
      _current = null;
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
      if (_current != null) {
        _pastClients.add(_current);
      }
      _current = _Client(TrackingClient(client));
      _current._useCount++;
      _nextCompleter.complete();
      return _current;
    } finally {
      _nextCompleter = null;
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
