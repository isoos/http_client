import 'dart:async';
import 'dart:io' as io;

import 'http_client.dart';
import 'src/headers.dart' show wrapHeaders;

export 'http_client.dart';

/// HTTP Client in console (server) environment.
class ConsoleClient implements Client {
  final io.HttpClient _delegate;
  final Headers _headers;

  ConsoleClient._(this._delegate, this._headers);

  /// HTTP Client in console (server) environment.
  ///
  /// Set [proxy] for static http proxy, or [proxyFn] for dynamic http proxy.
  /// Return format should be e.g. ""PROXY host:port; PROXY host2:port2; DIRECT"
  factory ConsoleClient({
    String proxy,
    String proxyFn(Uri uri),

    /* Headers | Map */
    dynamic headers,

    /// The idle timeout of non-active persistent (keep-alive) connections.
    Duration idleTimeout,

    /// the maximum number of live connections, to a single host.
    int maxConnectionsPerHost,

    /// Whether the body of a response will be automatically uncompressed.
    bool autoUncompress,

    /// The default value of the `User-Agent` header for all requests.
    /// Set to empty string to disable setting the User-Agent header automatically.
    String userAgent,
  }) {
    final delegate = new io.HttpClient();
    if (proxy != null) {
      delegate.findProxy = (uri) => proxy;
    } else if (proxyFn != null) {
      delegate.findProxy = proxyFn;
    }
    if (idleTimeout != null) {
      delegate.idleTimeout = idleTimeout;
    }
    if (maxConnectionsPerHost != null) {
      delegate.maxConnectionsPerHost = maxConnectionsPerHost;
    }
    if (autoUncompress != null) {
      delegate.autoUncompress = autoUncompress;
    }
    if (userAgent != null) {
      delegate.userAgent = userAgent.isEmpty ? null : userAgent;
    }
    return new ConsoleClient._(delegate, wrapHeaders(headers));
  }

  @override
  Future<Response> send(Request request) async {
    final rq = await _delegate.openUrl(request.method, request.uri);

    void applyHeader(Headers headers, String key) {
      final List<String> values = headers[key];
      if (values == null || values.isEmpty) return;
      if (values.length == 1) {
        rq.headers.set(key, values.single);
      } else {
        rq.headers.set(key, values);
      }
    }

    if (request.headers != null) {
      for (String key in request.headers.keys) {
        applyHeader(request.headers, key);
      }
    }
    if (_headers != null) {
      for (String key in _headers.keys) {
        if (request.headers != null && request.headers.containsKey(key)) {
          continue;
        }
        applyHeader(_headers, key);
      }
    }

    if (request.persistentConnection != null) {
      rq.persistentConnection = request.persistentConnection;
    }
    if (request.followRedirects != null) {
      rq.followRedirects = request.followRedirects;
    }
    if (request.maxRedirects != null) {
      rq.maxRedirects = request.maxRedirects;
    }

    // sending body
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

    return new Response(
      rs.statusCode,
      rs.reasonPhrase,
      headers,
      rs,
      redirects: rs?.redirects
          ?.map((ri) => new RedirectInfo(ri.statusCode, ri.method, ri.location))
          ?.toList(),
      requestAddress: rq?.connectionInfo?.remoteAddress?.address,
      responseAddress: rs?.connectionInfo?.remoteAddress?.address,
    );
  }

  @override
  Future close({bool force = false}) async {
    _delegate.close(force: force);
  }
}
