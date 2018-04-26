import 'dart:async';
import 'dart:convert';

import 'src/headers.dart';
export 'src/headers.dart' show Headers;

/// HTTP Client interface.
abstract class Client {
  /// Sends the [request] and returns the [Response]
  Future<Response> send(Request request);

  /// Closes any HTTP Client resources.
  Future close();
}

/// HTTP Request object
class Request {
  /// HTTP method
  final String method;

  /// target URI
  final Uri uri;

  /// HTTP Headers
  final Headers headers;

  /// The body content as stream (if any). If the bytes are available
  /// synchronously, they will be put in [bodyBytes] and [bodyStream] will be
  /// null.
  final Stream<List<int>> bodyStream;

  /// The body content as bytes (if any). If the bytes are available
  /// asynchronously, they will be put in [bodyStream] and [bodyBytes] will be
  /// null.
  final List<int> bodyBytes;

  /// Creates a HTTP Request object.
  factory Request(
    String method,
    dynamic uri, {
    dynamic headers,
    dynamic body,
    Encoding encoding: utf8,
  }) {
    assert(uri is String || uri is Uri);
    final Uri parsedUri = uri is Uri ? uri : Uri.parse(uri.toString());
    List<int> bodyBytes;
    Stream<List<int>> bodyStream;
    if (body is String) {
      bodyBytes = encoding.encode(body);
    } else if (body is List<int>) {
      bodyBytes = body;
    } else if (body is Stream<List<int>>) {
      bodyStream = body;
    } else if (body != null) {
      throw new Exception('Unable to parse body: $body');
    }
    return new Request._(
        method, parsedUri, wrapHeaders(headers), bodyBytes, bodyStream);
  }

  Request._(
      this.method, this.uri, this.headers, this.bodyBytes, this.bodyStream);
}

/// A HTTP Response object.
class Response {
  /// HTTP Status code
  final int statusCode;

  /// HTTP reason phrase
  final String reasonPhrase;

  /// HTTP headers
  final Headers headers;

  final String _bodyText;
  final List<int> _bodyBytes;
  Stream<List<int>> _body;

  /// Creates a HTTP Response object with stream response type.
  Response(this.statusCode, this.reasonPhrase, this.headers, this._body)
      : _bodyText = null,
        _bodyBytes = null;

  /// Creates a HTTP Response object with text response type.
  Response.withText(
      this.statusCode, this.reasonPhrase, this.headers, String text)
      : _bodyText = text,
        _bodyBytes = null;

  /// Creates a HTTP Response object with bytes response type.
  Response.withBytes(
      this.statusCode, this.reasonPhrase, this.headers, List<int> bytes)
      : _bodyText = null,
        _bodyBytes = bytes;

  /// HTTP body
  Stream<List<int>> get body {
    if (_body != null) {
      return _body;
    }
    if (_bodyBytes != null) {
      _body ??= new Stream.fromIterable([_bodyBytes]);
      return _body;
    }
    if (_bodyText != null) {
      _body ??= new Stream.fromIterable([utf8.encode(_bodyText)]);
    }
    return null;
  }

  /// Reads the [body] as String with [encoding]
  Future<String> readAsString({Encoding encoding}) {
    // TODO: detect encoding from headers
    encoding ??= utf8;
    if (encoding == utf8 && _bodyText != null) {
      return new Future.value(_bodyText);
    }
    if (_bodyBytes != null) {
      return new Future.value(encoding.decode(_bodyBytes));
    }
    return encoding.decodeStream(body);
  }
}
