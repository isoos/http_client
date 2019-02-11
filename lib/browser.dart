import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'http_client.dart';
export 'http_client.dart';

/// HTTP Client in browser environment.
class BrowserClient implements Client {
  @override
  Future<Response> send(Request request) async {
    ByteBuffer buffer;

    if (request.body is List<int>) {
      buffer = castBytes(request.body as List<int>).buffer;
    } else if (request.body is StreamFn) {
      final fn = request.body as StreamFn;
      final data = await readAsBytes(await fn());
      buffer = data.buffer;
    }

    final sendData = buffer ?? request.body;
    final rs = await html.HttpRequest.request(
      request.uri.toString(),
      method: request.method,
      requestHeaders: request.headers?.toSimpleMap(),
      sendData: sendData,
    );
    final response = rs.response;
    final headers = new Headers(rs.responseHeaders);
    if (response is ByteBuffer) {
      return new Response(
          rs.status, rs.statusText, headers, response.asUint8List());
    } else {
      return new Response(rs.status, rs.statusText, headers, response);
    }
  }

  @override
  Future close({bool force = false}) async {
    // TODO: throw exception on send() when the [BrowserClient] is closed.
  }
}
