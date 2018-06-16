import 'package:test/test.dart';

import 'package:http_client/http_client.dart';

void main() {
  test('Initialize from misc Map', () {
    final headers = new Headers({'ak': 'av', 'bk': ['bv1', 'bv2']});
    expect(headers.toMap(), {'ak': ['av'], 'bk': ['bv1', 'bv2']});
    expect(headers.toSimpleMap(), {'ak': 'av', 'bk': 'bv2'});
  });

  test('Initialize from non-String values', () {
    final headers = new Headers({'a': 1, 'b': [bool]});
    expect(headers.toSimpleMap(), {'a': '1', 'b': 'bool'});
  });
}
