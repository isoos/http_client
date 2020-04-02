import 'dart:async';
import 'dart:convert' as c;

import 'package:buffer/buffer.dart' as buffer;

import 'src/headers.dart';

export 'src/headers.dart' show Headers;
export 'src/tracking_client.dart';
export 'src/updating_client.dart';

/// A restartable input stream.
typedef StreamFn = FutureOr<Stream<List<int>>> Function();

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

  /// The body content in a form that enables retries (in most cases).
  /// It can be List<int> (binary content), [StreamFn], or File (on console-only).
  final dynamic body;

  /// The requested persistent connection state.
  final bool persistentConnection;

  /// Whether this request should automatically follow redirects.
  final bool followRedirects;

  /// The maximum number of redirects to follow when [followRedirects] is `true`.
  final int maxRedirects;

  /// The timeout for the underlying HTTP request. Framework-related overheads,
  /// e.g. scheduling or proxy initialization is not counted against this time.
  final Duration timeout;

  /// Creates a HTTP Request object.
  factory Request(
    String method,
    dynamic uri, {
    dynamic headers,
    dynamic body,
    Map<String, dynamic> form,
    dynamic json,
    Map<String, String> cookies,
    c.Encoding encoding,
    bool persistentConnection,
    bool followRedirects,
    int maxRedirects,
    Duration timeout,
  }) {
    assert(uri is String || uri is Uri);
    encoding ??= c.utf8;
    final parsedUri = uri is Uri ? uri : Uri.parse(uri.toString());
    final newHeaders = wrapHeaders(headers, clone: true);
    body = _buildBody(body, encoding, newHeaders, form, json, cookies);
    return Request._(
      method,
      parsedUri,
      newHeaders,
      body,
      persistentConnection,
      followRedirects,
      maxRedirects,
      timeout,
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
    this.timeout,
  );

  /// Creates a [Request] object by changing or augmenting the properties.
  ///
  /// When [uri], [headers] or [body] is specified, they will override the
  /// original corresponding values.
  ///
  /// Use [patchHeaders] to keep the current headers and also add override its
  /// values (if they already exist) or add values (if they did not exist).
  Request change({
    dynamic uri,
    dynamic headers,
    dynamic patchHeaders,
    dynamic body,
    Map<String, dynamic> form,
    Map<String, dynamic> json,
    Map<String, String> cookies,
    c.Encoding encoding,
  }) {
    encoding ??= c.utf8;
    Uri parsedUri;
    if (uri != null) {
      assert(uri is String || uri is Uri);
      parsedUri = uri is Uri ? uri : Uri.parse(uri.toString());
    }

    final newHeaders = headers == null
        ? this.headers.clone()
        : wrapHeaders(headers, clone: true);
    if (patchHeaders != null) {
      final patching = wrapHeaders(patchHeaders);
      patching.keys.forEach((key) {
        newHeaders.remove(key);
        newHeaders.add(key, patching[key]);
      });
    }

    final newBody = _buildBody(
        body ?? this.body, encoding, newHeaders, form, json, cookies);

    return Request._(
      method,
      parsedUri ?? this.uri,
      newHeaders,
      newBody,
      persistentConnection,
      followRedirects,
      maxRedirects,
      timeout,
    );
  }
}

/// A HTTP Response object.
class Response {
  /// HTTP Status code
  final int statusCode;

  /// HTTP reason phrase
  final String reasonPhrase;

  /// HTTP headers
  final Headers headers;

  dynamic _body;
  String _bodyText;
  List<int> _bodyBytes;
  Stream<List<int>> _bodyStream;
  Completer _doneCompleter;

  /// The redirect steps that happened.
  final List<RedirectInfo> redirects;

  /// The remote address that the response was opened at.
  final String requestAddress;

  /// The remote address that the response was returned from.
  final String responseAddress;

  /// Creates a HTTP Response object.
  Response(
    this.statusCode,
    this.reasonPhrase,
    this.headers,
    dynamic body, {
    this.redirects,
    this.requestAddress,
    this.responseAddress,
  }) {
    if (body is String) {
      _bodyText = body;
    } else if (body is List<int>) {
      _bodyBytes = body;
    } else if (body is Stream<List<int>>) {
      _doneCompleter = Completer();
      _bodyStream =
          body.transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleDone: (sink) {
          sink.close();
          _doneCompleter.complete();
        },
      ));
    } else {
      _body = body;
    }
  }

  /// HTTP body content.
  dynamic get body {
    return _bodyText ?? _bodyBytes ?? _bodyStream ?? _body;
  }

  /// HTTP body content as Stream.
  Stream<List<int>> get bodyAsStream {
    if (_bodyStream != null) {
      return _bodyStream;
    }
    if (_bodyBytes != null) {
      _bodyStream ??= Stream.fromIterable([_bodyBytes]);
      return _bodyStream;
    }
    if (_bodyText != null) {
      _bodyStream ??= Stream.fromIterable([c.utf8.encode(_bodyText)]);
    }
    if (_body != null) {
      throw StateError('Unable to convert body to Stream');
    }
    return null;
  }

  /// Reads the body content as String with [encoding]
  Future<String> readAsString({c.Encoding encoding}) {
    // TODO: detect encoding from headers
    encoding ??= c.utf8;
    if (encoding == c.utf8 && _bodyText != null) {
      return Future.value(_bodyText);
    }
    if (_bodyBytes != null) {
      return Future.value(encoding.decode(_bodyBytes));
    }
    if (_bodyStream != null) {
      return encoding.decodeStream(_bodyStream);
    }
    if (_body != null) {
      throw StateError('Unable to convert body to String');
    }
    return null;
  }

  /// Reads the body content as bytes.
  Future<List<int>> readAsBytes() async {
    if (_bodyText != null) {
      return c.utf8.encode(_bodyText);
    }
    if (_bodyBytes != null) {
      return _bodyBytes;
    }
    if (_bodyStream != null) {
      return buffer.readAsBytes(_bodyStream);
    }
    if (_body != null) {
      throw StateError('Unable to convert body to bytes');
    }
    return null;
  }

  /// Completes when the underlying input stream has been read and completed.
  Future get done async {
    await _doneCompleter?.future;
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

String _encodeFormData(Map<String, dynamic> formData) {
  final parts = <String>[];
  for (final key in formData.keys) {
    final keyEncoded = Uri.encodeQueryComponent(key);
    void addValue(v) {
      parts.add(keyEncoded + '=' + Uri.encodeQueryComponent(v.toString()));
    }

    final value = formData[key];
    if (value is Iterable) {
      value.forEach(addValue);
    } else {
      addValue(value);
    }
  }
  return parts.join('&');
}

dynamic _buildBody(
    oldBody,
    c.Encoding encoding,
    Headers newHeaders,
    Map<String, dynamic> form,
    Map<String, dynamic> json,
    Map<String, String> cookies) {
  dynamic body = oldBody;
  String contentType;
  if (form != null) {
    if (body != null) {
      throw ArgumentError('body is specified multiple times (form)');
    }
    body = _encodeFormData(form);
    contentType = 'application/x-www-form-urlencoded';
  }
  if (json != null) {
    if (body != null) {
      throw ArgumentError('body is specified multiple times (json)');
    }
    body = c.json.encode(json);
    contentType = 'application/json';
  }
  if (contentType != null) {
    contentType += '; charset=${encoding.name}';
  }
  if (body is String) {
    body = encoding.encode(body);
  } else if (body is Map<String, dynamic>) {
    body = encoding.encode(_encodeFormData(body));
  }
  if (!newHeaders.containsKey('content-type')) {
    newHeaders.add('content-type', contentType);
  }
  if (cookies != null) {
    if (newHeaders.containsKey('cookie')) {
      throw ArgumentError('cookie header is already specified.');
    }
    final v = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    newHeaders.add('cookie', v);
  }
  return body;
}
