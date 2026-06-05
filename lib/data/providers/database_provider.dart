import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';

/// The single app-wide database instance, closed when the container disposes.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Reactive list of clients (newest first).
///
/// On platforms without the native database (e.g. the web preview) this emits
/// an error, which screens render as a friendly "runs on-device" state.
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(databaseProvider).watchClients();
});
