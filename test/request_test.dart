import 'package:test/test.dart';

import 'package:http_client/http_client.dart';

void main() {
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
