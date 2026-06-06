import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_store.dart';

/// Shared [SecureStore] instance (vault DEK + GitHub token live here).
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());
