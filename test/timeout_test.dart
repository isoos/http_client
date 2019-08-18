import 'dart:async';

import 'package:test/test.dart';

import 'package:http_client/http_client.dart';
import 'package:http_client/console.dart';

void main() {
  test('timeout', () async {
    final client = UpdatingClient(createClientFn: () async => ConsoleClient());
    final rs = client.send(Request(
      'GET',
      'http://slowwly.robertomurray.co.uk/delay/3000/url/https://www.google.com/',
      followRedirects: false,
      timeout: Duration(seconds: 1),
    ));
    await expectLater(rs, throwsA(isA<TimeoutException>()));
    await client.close();
  });
}
