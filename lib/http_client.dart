import 'dart:async';
import 'dart:convert';

import 'src/headers.dart';

export 'src/headers.dart' show Headers;
export 'src/tracking_client.dart';
export 'src/updating_client.dart';

/// A restartable input stream.
typedef FutureOr<Stream<List<int>>> StreamFn();

/// HTTP Client interface.
abstract class Client {
  /// Sends the [request] and returns the [Response]
  Future<Response> send(Request request);

  /// Closes any HTTP Client resources.
  ///
  /// If [force] is `false` (the default) the [Client] will be kept alive
  /// until all active connections are done. If [force] is `true` any active
  /// connections will be closed to immediately release all resources
  /// (subject to platform support).
  Future close({bool force = false});
}

/// HTTP Request object
class Request {
  /// HTTP method
  final String method;

  /// target URI
  final Uri uri;

  /// HTTP Headers
  final Headers headers;

  /// The body content in a form that enables retries.
  /// It can be String, List<int> (binary content), Map<String, dynamic> (form
  /// data), or File (on console-only).
  final dynamic body;

  /// The requested persistent connection state.
  final bool persistentConnection;

  /// Whether this request should automatically follow redirects.
  final bool followRedirects;

  /// The maximum number of redirects to follow when [followRedirects] is `true`.
  final int maxRedirects;

  /// Creates a HTTP Request object.
  factory Request(
    String method,
    dynamic uri, {
    dynamic headers,
    dynamic body,
    Encoding encoding: utf8,
    bool persistentConnection,
    bool followRedirects,
    int maxRedirects,
  }) {
    assert(uri is String || uri is Uri);
    final Uri parsedUri = uri is Uri ? uri : Uri.parse(uri.toString());
    List<int> bodyBytes;
    if (body is String) {
      bodyBytes = encoding.encode(body);
    } else if (body is List<int>) {
      bodyBytes = body;
    } else if (body is Map<String, dynamic>) {
      final parts = <String>[];
      for (String key in body.keys) {
        final keyEncoded = Uri.encodeQueryComponent(key);
        void addValue(v) {
          parts.add(keyEncoded + '=' + Uri.encodeQueryComponent(v.toString()));
        }

        final value = body[key];
        if (value is List) {
          value.forEach(addValue);
        } else {
          addValue(value);
        }
      }
      bodyBytes = encoding.encode(parts.join('&'));
    } else if (body is Stream<List<int>>) {
      throw ArgumentError(
          'Stream<List<int>> is not supported as body, use StreamFn');
    }
    return new Request._(
      method,
      parsedUri,
      wrapHeaders(headers),
      bodyBytes ?? body,
      persistentConnection,
      followRedirects,
      maxRedirects,
    );
  }

  Request._(
    this.method,
    this.uri,
    this.headers,
    this.body,
    this.persistentConnection,
    this.followRedirects,
    this.maxRedirects,
  );
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
  final Completer _bodyDone;

  /// The redirect steps that happened.
  final List<RedirectInfo> redirects;

  /// The remote address that the response was opened at.
  final String requestAddress;

  /// The remote address that the response was returned from.
  final String responseAddress;

  /// Creates a HTTP Response object with stream response type.
  Response(
    this.statusCode,
    this.reasonPhrase,
    this.headers,
    Stream<List<int>> body, {
    this.redirects,
    this.requestAddress,
    this.responseAddress,
  })  : _bodyText = null,
        _bodyBytes = null,
        _bodyDone = Completer() {
    _body = body.transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleDone: (sink) {
        sink.close();
        _bodyDone.complete();
      },
    ));
  }

  /// Creates a HTTP Response object with text response type.
  Response.withText(
    this.statusCode,
    this.reasonPhrase,
    this.headers,
    String text, {
    this.redirects,
    this.requestAddress,
    this.responseAddress,
  })  : _bodyText = text,
        _bodyBytes = null,
        _bodyDone = null;

  /// Creates a HTTP Response object with bytes response type.
  Response.withBytes(
    this.statusCode,
    this.reasonPhrase,
    this.headers,
    List<int> bytes, {
    this.redirects,
    this.requestAddress,
    this.responseAddress,
  })  : _bodyText = null,
        _bodyBytes = bytes,
        _bodyDone = null;

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

  /// Completes when the underlying input stream has been read and completed.
  Future get done async {
    await _bodyDone?.future;
  }
}

/// Information about the redirect step.
class RedirectInfo {
  /// The status code of the redirect.
  final int statusCode;

  /// The method of the redirect.
  final String method;

  /// The location of the redirect.
  final Uri location;

  ///
  RedirectInfo(this.statusCode, this.method, this.location);
}
