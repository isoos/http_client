import 'dart:async';

import 'package:test/test.dart';

import 'package:http_client/console.dart';

void main() {
  test('timeout', () async {
    final client = UpdatingClient(createClientFn: () async => ConsoleClient());
    final rs = client.send(Request(
      'GET',
      'https://httpstat.us/504?sleep=3000',
      followRedirects: false,
      timeout: Duration(seconds: 1),
    ));
    await expectLater(rs, throwsA(isA<TimeoutException>()));
    await client.close();
  });
}
