import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/data/parse_list.dart';

void main() {
  test('parseJsonList maps objects', () {
    final items = parseJsonList(
      [
        {'id': '1'},
        {'id': '2'},
      ],
      (json) => json['id'] as String,
    );
    expect(items, ['1', '2']);
  });
}
