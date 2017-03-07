# HTTP client wrapper

Wrapper of the [http](https://pub.dartlang.org/packages/http) package
to provide a single interface for both browser and console clients,
until it will support it out of the box.

## Usage:

To develop your platform-agnostic library, use only the base import:

````dart
import 'package:http_client/http_client.dart';

class MyServiceClient {
  final BaseClient httpClient;
  MyServiceClient(this.httpClient);
}
````

For console apps:

````dart
import 'package:http_client/console.dart';
import 'package:http_client/http_client.dart';

main() {
  BaseClient client = newHttpClient();
  // use the client, eg.:
  // new MyServiceClient(client)
}
````

For browser use, only change the first import:

````dart
import 'package:http_client/browser.dart';
import 'package:http_client/http_client.dart';

main() {
  BaseClient client = newHttpClient();
  // use the client, eg.:
  // new MyServiceClient(client)
}
````
