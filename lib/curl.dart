import 'dart:async';
import 'dart:io';

import 'http_client.dart';
export 'http_client.dart';

/// HTTP Client in Linux environment, executing the `curl` binary.
/// Use it only if the required feature (e.g. SOCKS proxy) is not available in
/// `console.dart`'s `ConsoleClient`.
class CurlClient implements Client {
  /// The `curl` executable.
  final String executable;

  /// The HTTP user agent.
  final String userAgent;

  /// SOCKS5 Proxy in `host:port` format.
  final String socksHostPort;

  /// HTTP Client in Linux environment, executing the `curl` binary.
  CurlClient({this.executable, this.userAgent, this.socksHostPort});

  @override
  Future<Response> send(Request request) async {
    if (request.bodyBytes != null || request.bodyStream != null) {
      throw new Exception('Sending body is not yet supported.');
    }
    final List<String> args = ['-L'];
    if (userAgent != null) args.addAll(['-A', userAgent]);
    if (socksHostPort != null) args.addAll(['--socks5', socksHostPort]);
    final String method = request.method ?? 'GET';
    args.addAll(['-X', method.toUpperCase()]);
    // TODO: add data processing, e.g. for strings:
    // if (data != null) args.addAll(['--data', data]);
    args.add(request.uri.toString());
    // TODO: handle status code and reason phrase
    final ProcessResult pr =
        await Process.run(executable ?? 'curl', args, stdoutEncoding: null);
    final List<int> list = pr.stdout;
    return new Response(pr.exitCode == 0 ? 200 : -1, null, new Headers(),
        new Stream.fromIterable(<List<int>>[list]));
  }

  @override
  Future close() async {}
}
