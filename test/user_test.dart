// test/user_test.dart
import 'package:expense_tracker_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.hashPassword / verifyPassword', () {
    test('hash has salt:hash format and is long enough', () {
      final h = User.hashPassword('123456');
      expect(h.contains(':'), isTrue);
      expect(h.length, greaterThan(60));
    });

    test('verifies correct password', () {
      final h = User.hashPassword('123456');
      expect(User.verifyPassword('123456', h), isTrue);
    });

    test('rejects wrong password', () {
      final h = User.hashPassword('123456');
      expect(User.verifyPassword('654321', h), isFalse);
    });

    test('two hashes of the same password differ (random salt)', () {
      final a = User.hashPassword('same');
      final b = User.hashPassword('same');
      expect(a, isNot(equals(b)));
    });

    test('rejects malformed stored value', () {
      expect(User.verifyPassword('x', 'no-colon-here'), isFalse);
    });
  });
}