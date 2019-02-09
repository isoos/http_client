import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'http_client.dart';
export 'http_client.dart';

/// HTTP Client in browser environment.
class BrowserClient implements Client {
  @override
  Future<Response> send(Request request) async {
    ByteBuffer buffer;

    if (request.bodyBytes != null) {
      buffer = new Uint8List.fromList(request.bodyBytes).buffer;
    } else if (request.bodyStream != null) {
      buffer = new Uint8List.fromList(
              await request.bodyStream.fold([], (l1, l2) => l1..addAll(l2)))
          .buffer;
    }

    final rs = await html.HttpRequest.request(
      request.uri.toString(),
      method: request.method,
      requestHeaders: request.headers?.toSimpleMap(),
      sendData: buffer,
    );
    final response = rs.response;
    final headers = new Headers(rs.responseHeaders);
    if (response is ByteBuffer) {
      return new Response.withBytes(
          rs.status, rs.statusText, headers, response.asInt8List().toList());
    } else if (response is String) {
      return new Response.withText(rs.status, rs.statusText, headers, response);
    } else {
      return new Response(rs.status, rs.statusText, headers, null);
    }
  }

  @override
  Future close({bool force = false}) async {
    // TODO: throw exception on send() when the [BrowserClient] is closed.
  }
}
