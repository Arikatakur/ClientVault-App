import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The on-device SQLite database. `driftDatabase` opens a native, file-backed
/// database on iOS/Android (and desktop); a test executor can be injected.
@DriftDatabase(tables: [Clients, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'clientvault'));

  @override
  int get schemaVersion => 1;

  // --- Clients ---------------------------------------------------------------

  /// Watches all clients, newest first.
  Stream<List<Client>> watchClients() {
    return (select(clients)..orderBy([
          (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<int> insertClient(ClientsCompanion entry) =>
      into(clients).insert(entry);

  Future<int> deleteClient(String id) =>
      (delete(clients)..where((c) => c.id.equals(id))).go();
}
