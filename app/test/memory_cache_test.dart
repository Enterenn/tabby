import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/cache/memory_cache.dart';

void main() {
  test('deduplicates concurrent loads and caches the result', () async {
    final cache = MemoryCache<int>();
    var calls = 0;

    Future<int> load() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return 42;
    }

    final values = await Future.wait([cache.getOrLoad(load), cache.getOrLoad(load)]);

    expect(values, [42, 42]);
    expect(calls, 1);
    expect(await cache.getOrLoad(load), 42);
    expect(calls, 1);
  });

  test('force reload bypasses fresh cache', () async {
    final cache = MemoryCache<int>();
    var calls = 0;

    Future<int> load() async => ++calls;

    expect(await cache.getOrLoad(load), 1);
    expect(await cache.getOrLoad(load, force: true), 2);
  });
}
