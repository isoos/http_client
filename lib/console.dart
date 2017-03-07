import 'package:http/http.dart';
export 'package:http/http.dart';

export 'http_client.dart';

/// Creates a new HTTP client instance.
BaseClient newHttpClient() => new IOClient();
