import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'http_client.dart';
export 'http_client.dart';

/// SOCKS is a protocol used for proxies and curl supports it. curl supports both SOCKS version 4 as well as version 5, and both versions come in two flavors.
/// https://ec.haxx.se/usingcurl/usingcurl-proxies#socks-types
enum CurlSocksProxyType {
  /// SOCKS4 is for the version 4
  socks4,

  /// SOCKS4a is for the version 4 without resolving the host name locally
  socks4a,

  /// SOCKS5 is for the version 5
  socks5,

  /// SOCKS5-hostname is for the version 5 without resolving the host name locally
  socks5hostname,
}

/// HTTP Client in Linux environment, executing the `curl` binary.
/// Use it only if the required feature (e.g. SOCKS proxy) is not available in
/// `console.dart`'s `ConsoleClient`.
class CurlClient implements Client {
  /// The `curl` executable.
  final String? executable;

  /// The HTTP user agent.
  final String? userAgent;

  /// SOCKS Proxy in `host:port` format.
  final String? socksHostPort;

  /// SOCKS Proxy type. Default is SOCKS5.
  final CurlSocksProxyType socksProxyType;

  /// HTTP Client in Linux environment, executing the `curl` binary.
  CurlClient({
    this.executable,
    this.userAgent,
    this.socksHostPort,
    this.socksProxyType = CurlSocksProxyType.socks5,
  });

  bool methodSupportsBody(String method) {
    // According to HTTP/1.1 (RFC 7231), the following methods should not be allowed by servers: https://www.rfc-editor.org/rfc/rfc7231
    const methodsWithoutBody = {
      'GET',
      'HEAD',
      'DELETE',
      'CONNECT',
      'OPTIONS',
      'TRACE',
    };

    return !methodsWithoutBody.contains(method.toUpperCase());
  }

  @override
  Future<Response> send(Request request) async {
    final method = request.method;
    if (request.body != null && !methodSupportsBody(method)) {
      throw Exception('Sending body is not supported by requested method.');
    }
    final args = <String?>[];
    if (request.followRedirects == null || request.followRedirects!) {
      args.add('-L');
    }
    if (request.maxRedirects != null) {
      args.add('--max-redirs');
      args.add(request.maxRedirects.toString());
    }
    if (userAgent != null) args.addAll(['-A', userAgent]);

    if (socksHostPort != null) {
      switch (socksProxyType) {
        case CurlSocksProxyType.socks4:
          args.add('--socks4');
          break;
        case CurlSocksProxyType.socks4a:
          args.add('--socks4a');
          break;
        case CurlSocksProxyType.socks5:
          args.add('--socks5');
          break;
        case CurlSocksProxyType.socks5hostname:
          args.add('--socks5-hostname');
          break;
      }
      args.add(socksHostPort);
    }
    args.addAll(['-X', method.toUpperCase()]);

    request.headers.toSimpleMap().forEach((key, value) {
      args.addAll(['-H', '$key:$value']);
    });

    // --data parameter added in GET and POST Method. If method is 'GET', body may no have any effect in the request. UTF-8 encoding setted as default.
    if (request.body != null) {
      if (request.body is! List<int>) {
        throw Exception('Request body type must be List<int>');
      }
      args.addAll(['--data', utf8.decode(request.body)]);
    }
    args.add(request.uri.toString());
    // TODO: handle status code and reason phrase
    var prf = Process.run(executable ?? 'curl', args.where((element) => element != null).map((e) => e!).toList(),
        stdoutEncoding: null);
    if (request.timeout != null && request.timeout! > Duration.zero) {
      prf = prf.timeout(request.timeout!);
    }
    final pr = await prf;
    final list = (pr.stdout as List).cast<int>();
    return Response(pr.exitCode == 0 ? 200 : -1, '', Headers(),
        Stream.fromIterable(<List<int>>[list]));
  }

  @override
  Future close({bool force = false}) async {
    // TODO: throw exception on send() when the [CurlClient] is closed.
  }
}
