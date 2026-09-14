import 'dart:async';

class MemoryCache<T> {
  MemoryCache({this.ttl = const Duration(seconds: 30)});

  final Duration ttl;
  T? _value;
  DateTime? _storedAt;
  Future<T>? _inFlight;

  T? get value {
    if (_value == null || _storedAt == null) return null;
    if (DateTime.now().difference(_storedAt!) > ttl) return null;
    return _value;
  }

  bool get hasFreshValue => value != null;

  Future<T> getOrLoad(Future<T> Function() loader, {bool force = false}) {
    if (!force && hasFreshValue) return Future.value(_value);
    final current = _inFlight;
    if (current != null) return current;

    final request = loader();
    _inFlight = request;
    return request.then((result) {
      _value = result;
      _storedAt = DateTime.now();
      return result;
    }).whenComplete(() => _inFlight = null);
  }

  void set(T value) {
    _value = value;
    _storedAt = DateTime.now();
  }

  void invalidate() {
    _value = null;
    _storedAt = null;
  }
}
