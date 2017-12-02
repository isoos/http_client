# Platform-independent HTTP client

A platform-independent HTTP client API supporting browser, console,
and curl (for SOCKS proxy). Planned platforms: Fetch API, node_io.

## Usage:

To develop your platform-agnostic library, use only the base import:

````dart
import 'package:http_client/http_client.dart' as http;

class MyServiceClient {
  final http.Client httpClient;
  MyServiceClient(this.httpClient);
}
````

For console apps:

````dart
import 'package:http_client/console.dart' as http;

main() async {
  http.Client client = new http.ConsoleClient();
  // use the client, eg.:
  // new MyServiceClient(client)
  await client.close();
}
````

For browser use, only change the first import:

````dart
import 'package:http_client/browser.dart' as http;

main() {
  http.Client client = new http.BrowserClient();
  // use the client, eg.:
  // new MyServiceClient(client)
  await client.close();
}
````
