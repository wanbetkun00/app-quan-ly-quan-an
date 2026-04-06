import 'package:do_an_mon_quanlyquanan/services/password_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordService', () {
    test('hashPassword returns salted hash, not raw password', () {
      final service = PasswordService();

      final hashed = service.hashPassword('1234');

      expect(hashed, isNot('1234'));
      expect(service.isHashed(hashed), isTrue);
      expect(hashed.contains(':'), isTrue);
    });

    test('verifyPassword succeeds for the original password', () {
      final service = PasswordService();
      final hashed = service.hashPassword('abcDEF!234');

      final ok = service.verifyPassword('abcDEF!234', hashed);

      expect(ok, isTrue);
    });

    test('verifyPassword fails for wrong password against hash', () {
      final service = PasswordService();
      final hashed = service.hashPassword('abcDEF!234');

      final ok = service.verifyPassword('wrong', hashed);

      expect(ok, isFalse);
    });

    test('verifyPassword supports legacy plain text values', () {
      final service = PasswordService();

      expect(service.verifyPassword('1234', '1234'), isTrue);
      expect(service.verifyPassword('wrong', '1234'), isFalse);
      expect(service.isHashed('1234'), isFalse);
    });
  });
}
