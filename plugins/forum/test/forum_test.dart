import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    print('-------------------------');
    print(pi);
    print('-------------------------');
    print(sin(0));
    print('-------------------------');
    print(sin(pi / 4));
    print('-------------------------');
    print(sin(pi / 2));
    print('-------------------------');
    print(sin(pi / 4 * 3));
    print('-------------------------');
    print(sin(pi));
    print('-------------------------');
    print(sqrt(25 + 25));
    print('-------------------------');
    print(cos(0.1 * 180));
    print('-------------------------');
  });

  test('description', () {
    final r = 0.7853981633974483;
    final src = Offset(122.6, 193.2);
    final cx = src.dx + 180.0 / 2;
    final cy = src.dy + 216.0 / 2;
    final dx = src.dx - cx;
    final dy = src.dy - cy;
    final p = Offset(
      dx * cos(r) - dy * sin(r) + cx,
      dx * sin(r) + dy * cos(r) + cy,
    );
    print(p);
  });
}
