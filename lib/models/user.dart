// models/user.dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class User {
  int? id;
  final String username;
  final String email;
  final String password; // مخزّنة بصيغة "salt:sha256hex"

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  /// يجزّئ كلمة المرور باستخدام salt عشوائي لكل مستخدم.
  /// صيغة التخزين: `<base64Salt>:<hexSha256(salt+password)>`.
  static String hashPassword(String plaintext) {
    final salt = _randomSalt();
    final digest = sha256.convert(utf8.encode('$salt$plaintext'));
    return '$salt:$digest';
  }

  /// يتحقق من كلمة مرور نصية مقابل التخزين المُجزَّأ.
  /// يعيد false إذا كان التخزين لا يطابق الصيغة المتوقعة.
  static bool verifyPassword(String plaintext, String stored) {
    final idx = stored.indexOf(':');
    if (idx <= 0 || idx == stored.length - 1) return false;
    final salt = stored.substring(0, idx);
    final expected = stored.substring(idx + 1);
    final actual = sha256.convert(utf8.encode('$salt$plaintext')).toString();
    return actual == expected;
  }

  static String _randomSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64.encode(bytes);
  }
}