import 'package:flutter/material.dart';

/// The kind of secret a vault item holds. [value] is persisted plaintext (so
/// the list can filter without decrypting); [label] and [icon] drive the UI.
enum VaultItemType {
  password('password', 'Password', Icons.password),
  apiKey('apiKey', 'API key', Icons.vpn_key_outlined),
  account('account', 'Account', Icons.account_circle_outlined),
  note('note', 'Secure note', Icons.sticky_note_2_outlined),
  card('card', 'Card', Icons.credit_card_outlined);

  const VaultItemType(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// The primary secret's field label for this type (e.g. "Password", "Key").
  String get secretLabel => switch (this) {
    VaultItemType.password => 'Password',
    VaultItemType.apiKey => 'API key',
    VaultItemType.account => 'Password',
    VaultItemType.note => 'Note',
    VaultItemType.card => 'Card number',
  };

  static VaultItemType fromValue(String value) {
    return VaultItemType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => VaultItemType.password,
    );
  }
}
