// ignore_for_file: comment_references

/// HTTP Headers
/// [Headers] object is mutable and new values can be added up until
/// [Client.send] is called.
class Headers {
  final Map<String, List<String>> _values = {};

  /// Creates a new HTTP Header object, optinally using [values] as initializer.
  Headers([Map<String, dynamic> values]) {
    values?.forEach(add);
  }

  /// Returns the header names set.
  Iterable<String> get keys => _values.keys;

  /// Returns the values set for [header].
  List<String> operator [](String header) => _values[header];

  /// Add [header] with [value].
  ///
  /// [value] can be a List<String> or a String.
  void add(String header, dynamic value) {
    if (value == null) return;
    final List<String> list = _values.putIfAbsent(header, () => []);
    if (value is List) {
      list.addAll(value.map((o) => o.toString()));
    } else {
      list.add(value.toString());
    }
  }

  /// Remove [header].
  void remove(String header) {
    _values.remove(header);
  }

  /// Whether the [key] is specified.
  bool containsKey(String key) {
    return _values.containsKey(key);
  }

  /// Converts values to a simple String -> String Map.
  /// When multiple header values are present, only the last value is is used.
  Map<String, String> toSimpleMap() {
    final Map<String, String> result = {};
    _values.forEach((String header, List<String> values) {
      result[header] = values.last;
    });
    return result;
  }

  /// Gets a deep copy of the values.
  Map<String, List<String>> toMap() {
    return _values.map((k, v) => new MapEntry(k, new List<String>.from(v)));
  }
}

/// Properly wraps headers.
Headers wrapHeaders(dynamic headers) {
  if (headers == null) return null;
  if (headers is Headers) return headers;
  if (headers is Map<String, dynamic>) {
    return new Headers(headers);
  }
  throw new ArgumentError('Unknown headers type: ${headers.runtimeType}');
}
