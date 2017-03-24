import 'dart:async';

import 'package:http/browser_client.dart' as browser;
import 'package:http/http.dart' as http;

import 'http_client.dart';
export 'http_client.dart';

/// HTTP Client in browser environment. Delegates to `http` package.
class BrowserClient implements Client {
  browser.BrowserClient _delegate = new browser.BrowserClient();

  @override
  Future<Response> send(Request request) async {
    final rq = new http.Request(request.method, request.uri);
    if (request.headers != null) {
      rq.headers.addAll(request.headers.toSimpleMap());
    }
    if (request.bodyBytes != null) {
      rq.bodyBytes = request.bodyBytes;
    } else if (request.bodyStream != null) {
      rq.bodyBytes =
          await request.bodyStream.fold([], (l1, l2) => l1..addAll(l2));
    }
    final sr = await _delegate.send(rq);
    return new Response(
        sr.statusCode, sr.reasonPhrase, new Headers(sr.headers), sr.stream);
  }

  @override
  Future close() async {
    _delegate.close();
  }
}
