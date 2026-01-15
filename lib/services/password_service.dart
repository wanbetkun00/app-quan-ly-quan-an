import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordService {
  static const int _saltLength = 16;
  final Random _random = Random.secure();

  String hashPassword(String password) {
    final saltBytes = List<int>.generate(
      _saltLength,
      (_) => _random.nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    final digest = sha256.convert(utf8.encode('$salt$password')).toString();
    return '$salt:$digest';
  }

  bool verifyPassword(String password, String storedHash) {
    if (!isHashed(storedHash)) {
      return storedHash == password;
    }

    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expectedHash = parts[1];
    final computedHash =
        sha256.convert(utf8.encode('$salt$password')).toString();
    return _timingSafeEquals(expectedHash, computedHash);
  }

  bool isHashed(String value) {
    final parts = value.split(':');
    return parts.length == 2 && parts[1].length == 64;
  }

  bool _timingSafeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
