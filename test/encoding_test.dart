import 'dart:convert';

import 'package:test/test.dart';

import 'package:http_client/http_client.dart';

void main() {
  test('String request body', () {
    final rq = Request('GET', 'http://example.com/', body: 'abc');
    expect(utf8.decode(rq.bodyBytes), 'abc');
  });

  test('FORM params body', () {
    final rq = Request('GET', 'http://example.com/', body: {
      'a': 1,
      'b': [2, 3],
    });
    expect(utf8.decode(rq.bodyBytes), 'a=1&b=2&b=3');
  });
}
