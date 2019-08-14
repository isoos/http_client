// ignore_for_file: comment_references

/// HTTP Headers
/// [Headers] object is mutable and values can be added up until
/// [Client.send] is called.
class Headers {
  final Map<String, List<String>> _values = {};

  /// Creates a HTTP Header object, optinally using [values] as initializer.
  Headers([Map<String, dynamic> values]) {
    values?.forEach(add);
  }

  /// Creates a header object with the copy if the current one's content.
  Headers clone() => Headers(_values);

  /// Returns the header names set.
  Iterable<String> get keys => _values.keys;

  /// Returns the values set for [header].
  List<String> operator [](String header) => _values[header.toLowerCase()];

  /// Add [header] with [value].
  ///
  /// [value] can be a List<String> or a String.
  void add(String header, dynamic value) {
    if (value == null) return;
    final List<String> list =
        _values.putIfAbsent(header.toLowerCase(), () => []);
    if (value is List) {
      list.addAll(value.map((o) => o.toString()));
    } else {
      list.add(value.toString());
    }
  }

  /// Remove [header].
  void remove(String header) {
    _values.remove(header.toLowerCase());
  }

  /// Whether the [key] is specified.
  bool containsKey(String key) {
    return _values.containsKey(key.toLowerCase());
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
    return _values.map((k, v) => MapEntry(k, List<String>.from(v)));
  }
}

/// Properly wraps headers.
Headers wrapHeaders(dynamic headers, {bool clone = false}) {
  if (headers == null) {
    return clone ? Headers() : null;
  } else if (headers is Headers) {
    return clone ? headers.clone() : headers;
  } else if (headers is Map<String, dynamic>) {
    return Headers(headers);
  } else {
    throw ArgumentError('Unknown headers type: ${headers.runtimeType}');
  }
}
