import 'dart:convert';

/// Which identity provider an account came from. `local` means the account
/// lives only on this device (the pre-cloud mode); the rest map to Cognito
/// federation once the AWS backend is provisioned.
enum AuthProviderKind {
  local('local', 'On this device'),
  apple('apple', 'Apple'),
  google('google', 'Google'),
  cognito('cognito', 'ClientVault Cloud');

  const AuthProviderKind(this.value, this.label);

  final String value;
  final String label;

  static AuthProviderKind fromValue(String value) =>
      AuthProviderKind.values.firstWhere(
        (kind) => kind.value == value,
        orElse: () => AuthProviderKind.local,
      );
}

/// The signed-in identity. Deliberately independent from the vault master
/// password — account login and vault unlock are two separate factors.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.provider,
    required this.createdAt,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;
  final AuthProviderKind provider;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'provider': provider.value,
    'createdAt': createdAt.toIso8601String(),
  };

  static AppUser fromJson(Map<String, Object?> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    provider: AuthProviderKind.fromValue(json['provider'] as String? ?? ''),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  String toJsonString() => jsonEncode(toJson());

  static AppUser fromJsonString(String source) =>
      fromJson(jsonDecode(source) as Map<String, Object?>);
}

/// A user-facing authentication failure ([message] is shown verbatim).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
