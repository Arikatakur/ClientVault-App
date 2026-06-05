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

/// Reactive single client by id (emits `null` once the client is deleted).
final clientByIdProvider = StreamProvider.family<Client?, String>((ref, id) {
  return ref.watch(databaseProvider).watchClient(id);
});

/// Reactive list of every project (newest first).
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(databaseProvider).watchProjects();
});

/// Reactive list of the projects belonging to one client.
final clientProjectsProvider = StreamProvider.family<List<Project>, String>((
  ref,
  clientId,
) {
  return ref.watch(databaseProvider).watchProjectsForClient(clientId);
});

/// Reactive single project by id (emits `null` once the project is deleted).
final projectByIdProvider = StreamProvider.family<Project?, String>((ref, id) {
  return ref.watch(databaseProvider).watchProject(id);
});
