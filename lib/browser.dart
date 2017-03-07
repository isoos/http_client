import 'package:http/browser_client.dart';
export 'package:http/browser_client.dart';

import 'http_client.dart';
export 'http_client.dart';

/// Creates a new HTTP client instance.
BaseClient newHttpClient() => new BrowserClient();
