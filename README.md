# HTTP client wrapper

Wrapper of the [http](https://pub.dartlang.org/packages/http) package
to provide a single interface for both browser and console clients,
until it will support it out of the box.

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
