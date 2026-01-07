import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/stats/level_policy.dart';

void main() {
  test('calculates levels for xp thresholds and boundaries', () {
    const policy = LevelPolicy();

    expect(policy.levelForXp(0), 1);
    expect(policy.levelForXp(99), 1);
    expect(policy.levelForXp(100), 2);
    expect(policy.levelForXp(249), 2);
    expect(policy.levelForXp(250), 3);
    expect(policy.levelForXp(499), 3);
    expect(policy.levelForXp(500), 4);
    expect(policy.levelForXp(899), 4);
    expect(policy.levelForXp(900), 5);
  });
}
