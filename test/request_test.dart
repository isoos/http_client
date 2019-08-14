import 'dart:convert';

import 'package:test/test.dart';

import 'package:http_client/http_client.dart';

void main() {
  test('String request body', () {
    final rq = Request('GET', 'http://example.com/', body: 'abc');
    expect(utf8.decode(rq.body as List<int>), 'abc');
  });

  test('FORM params body', () {
    final rq = Request('GET', 'http://example.com/', body: {
      'a': 1,
      'b': [2, 3],
    });
    expect(utf8.decode(rq.body as List<int>), 'a=1&b=2&b=3');
  });

  test('form content', () {
    final rq = Request('GET', '/', form: {'a': 'aa', 'b': 'bb'});
    expect(rq.headers.toSimpleMap(), {
      'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
    });
    expect(utf8.decode(rq.body), 'a=aa&b=bb');
  });

  test('JSON content', () {
    final rq = Request('GET', '/', json: {'a': 'aa', 'b': 'bb'});
    expect(rq.headers.toSimpleMap(), {
      'content-type': 'application/json; charset=utf-8',
    });
    expect(utf8.decode(rq.body), '{"a":"aa","b":"bb"}');
  });

  test('cookies', () {
    final rq = Request('GET', '/', cookies: {'a': 'aa', 'b': 'bb'});
    expect(rq.headers.toSimpleMap(), {'cookie': 'a=aa; b=bb'});
  });

  test('Change empty headers', () {
    final rq = Request('GET', '/');
    final n = rq.change(headers: {'a': 'b'});
    expect(n.headers.toSimpleMap(), {'a': 'b'});
  });

  test('Override existing headers', () {
    final rq = Request('GET', '/', headers: {'a': 'a'});
    final n = rq.change(headers: {'a': 'b'});
    expect(n.headers.toSimpleMap(), {'a': 'b'});
  });

  test('Patch existing headers', () {
    final rq = Request('GET', '/', headers: {'a': 'a'});
    final n = rq.change(patchHeaders: {'a': 'b'});
    expect(n.headers.toSimpleMap(), {'a': 'b'});
  });

  test('Add new headers', () {
    final rq = Request('GET', '/', headers: {'a': 'a'});
    final n = rq.change(patchHeaders: {'b': 'b'});
    expect(n.headers.toSimpleMap(), {'a': 'a', 'b': 'b'});
  });
}
