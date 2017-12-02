import 'dart:async';
import 'dart:io' as io;

import 'http_client.dart';
export 'http_client.dart';

/// HTTP Client in browser environment. Delegates to `http` package.
class ConsoleClient implements Client {
  final io.HttpClient _delegate = new io.HttpClient();

  @override
  Future<Response> send(Request request) async {
    final rq = await _delegate.openUrl(request.method, request.uri);
    if (request.headers != null) {
      for (String key in request.headers.keys) {
        final List<String> values = request.headers[key];
        if (values == null || values.isEmpty) continue;
        if (values.length == 1) {
          rq.headers.set(key, values.single);
        } else {
          rq.headers.set(key, values);
        }
      }
    }
    if (request.bodyBytes != null) {
      rq.add(request.bodyBytes);
      await rq.close();
    } else if (request.bodyStream != null) {
      await request.bodyStream.pipe(rq);
    } else {
      await rq.close();
    }
    final rs = await rq.done;
    final Headers headers = new Headers();
    rs.headers.forEach((String key, List<String> values) {
      headers.add(key, values);
    });

    return new Response(rs.statusCode, rs.reasonPhrase, headers, rs);
  }

  @override
  Future close() async {
    _delegate.close(force: true);
  }
}
