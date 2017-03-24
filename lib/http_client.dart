import 'dart:async';
import 'dart:convert';

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
    Encoding encoding: UTF8,
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
    if (headers is Map) {
      headers = new Headers(headers);
    }
    return new Request._(method, parsedUri, headers, bodyBytes, bodyStream);
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

  /// HTTP body
  final Stream<List<int>> body;

  /// Creates a HTTP Response object.
  Response(this.statusCode, this.reasonPhrase, this.headers, this.body);

  /// Reads the [body] as String with [encoding]
  Future<String> readAsString({Encoding encoding}) {
    // TODO: detect encoding from headers
    encoding ??= UTF8;
    return encoding.decodeStream(body);
  }
}

/// HTTP Headers
/// [Headers] object is mutable and new values can be added up until
/// [Client.send] is called.
class Headers {
  Map<String, List<String>> _values = {};

  /// Creates a new HTTP Header object, optinally using [values] as initializer.
  Headers([Map<String, dynamic> values]) {
    values?.forEach(add);
  }

  /// Returns the header names set.
  Iterable<String> get keys => _values.keys;

  /// Returns the values set for [header].
  List<String> operator [](String header) => _values[header];

  /// Add [header] with [value].
  ///
  /// [value] can be a List<String> or a String.
  void add(String header, dynamic value) {
    if (value == null) return;
    final List<String> list = _values.putIfAbsent(header, () => []);
    if (value is List<String>) {
      list.addAll(value);
    } else {
      list.add(value.toString());
    }
  }

  /// Remove [header].
  void remove(String header) {
    _values.remove(header);
  }

  /// Converts values to a simple String -> String Map.
  /// When multiple header values are present, only the last value is is used.
  Map<String, String> toSimpleMap() {
    final Map<String, String> result = {};
    _values.forEach((String header, List<String> values) {
      result[header] = values.last;
    });
    return result;
  }
}
