import 'dart:async';

import 'package:executor/executor.dart';
export 'package:executor/executor.dart';

import 'http_client.dart';

/// Wraps a HTTP [Client] and limits its use with an [Executor].
class HttpExecutor extends Client {
  final Client _client;
  final Executor _executor;

  /// Wraps a HTTP [Client] and limits its use with an [Executor].
  HttpExecutor(this._client, this._executor);

  @override
  Future<Response> send(Request request) =>
      _executor.scheduleTask(() => _client.send(request));

  @override
  Future close({bool force = false}) async {
    await _executor.close();
    await _client.close(force: force);
  }
}
