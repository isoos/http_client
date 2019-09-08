import 'package:http/http.dart' as h;

import 'http_client.dart';

/// Adapter to use client instead of package:http
class PkgHttpAdapter extends h.BaseClient implements h.Client {
  final Client _client;

  ///
  PkgHttpAdapter(this._client);

  @override
  Future<h.StreamedResponse> send(h.BaseRequest request) async {
    final headers = <String, String>{};
    if (request.headers != null) {
      headers.addAll(request.headers);
    }
    if (request.contentLength != null) {
      headers['content-length'] ??= request.contentLength.toString();
    }
    final rs = await _client.send(
      Request(
        request.method,
        request.url,
        headers: headers,
        body: request.finalize(),
        followRedirects: request.followRedirects,
        maxRedirects: request.maxRedirects,
        persistentConnection: request.persistentConnection,
      ),
    );
    return h.StreamedResponse(
      rs.bodyAsStream,
      rs.statusCode,
      headers: rs.headers.toSimpleMap(),
      reasonPhrase: rs.reasonPhrase,
      request: request,
      isRedirect: rs.redirects != null && rs.redirects.isNotEmpty,
      contentLength: int.tryParse(rs.headers['content-length']?.first ?? ''),
    );
  }

  @override
  Future close({bool force}) async {
    await _client.close(force: force ?? false);
  }
}
