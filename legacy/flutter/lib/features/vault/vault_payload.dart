import 'dart:convert';

/// The decrypted contents of a vault item. Serialized to JSON, encrypted, and
/// stored as the item's ciphertext — so these fields never touch disk in the
/// clear. All fields are optional; which ones matter depends on the item type.
class VaultPayload {
  const VaultPayload({this.username, this.secret, this.url, this.notes});

  final String? username;

  /// The primary secret: password, API key, or card number.
  final String? secret;
  final String? url;
  final String? notes;

  factory VaultPayload.fromJson(Map<String, dynamic> json) {
    return VaultPayload(
      username: json['username'] as String?,
      secret: json['secret'] as String?,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (username != null) 'username': username,
    if (secret != null) 'secret': secret,
    if (url != null) 'url': url,
    if (notes != null) 'notes': notes,
  };

  List<int> toBytes() => utf8.encode(jsonEncode(toJson()));

  factory VaultPayload.fromBytes(List<int> bytes) {
    return VaultPayload.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }
}
