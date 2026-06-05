import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The on-device SQLite database. `driftDatabase` opens a native, file-backed
/// database on iOS/Android (and desktop); a test executor can be injected.
@DriftDatabase(tables: [Clients, Projects, VaultItems, VaultConfigs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'clientvault'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the encrypted vault (additive; existing data is preserved).
      if (from < 2) {
        await m.createTable(vaultItems);
        await m.createTable(vaultConfigs);
      }
    },
  );

  // --- Clients ---------------------------------------------------------------

  /// Watches all clients, newest first.
  Stream<List<Client>> watchClients() {
    return (select(clients)..orderBy([
          (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Watches a single client by id, emitting `null` once it is deleted.
  Stream<Client?> watchClient(String id) {
    return (select(clients)..where((c) => c.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertClient(ClientsCompanion entry) =>
      into(clients).insert(entry);

  /// Applies a partial update to the client with [id]. Only the fields set on
  /// [entry] are written, so callers pass `updatedAt` plus the edited columns.
  Future<int> updateClient(String id, ClientsCompanion entry) =>
      (update(clients)..where((c) => c.id.equals(id))).write(entry);

  /// Deletes a client and all of its projects in a single transaction, so the
  /// projects table is never left with orphaned rows.
  Future<void> deleteClient(String id) {
    return transaction(() async {
      await (delete(projects)..where((p) => p.clientId.equals(id))).go();
      await (delete(clients)..where((c) => c.id.equals(id))).go();
    });
  }

  // --- Projects --------------------------------------------------------------

  /// Watches all projects, newest first.
  Stream<List<Project>> watchProjects() {
    return (select(projects)..orderBy([
          (p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Watches the projects belonging to a single client, newest first.
  Stream<List<Project>> watchProjectsForClient(String clientId) {
    return (select(projects)
          ..where((p) => p.clientId.equals(clientId))
          ..orderBy([
            (p) =>
                OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watches a single project by id, emitting `null` once it is deleted.
  Stream<Project?> watchProject(String id) {
    return (select(projects)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<int> insertProject(ProjectsCompanion entry) =>
      into(projects).insert(entry);

  /// Applies a partial update to the project with [id].
  Future<int> updateProject(String id, ProjectsCompanion entry) =>
      (update(projects)..where((p) => p.id.equals(id))).write(entry);

  Future<int> deleteProject(String id) =>
      (delete(projects)..where((p) => p.id.equals(id))).go();

  // --- Vault -----------------------------------------------------------------

  /// The single vault crypto-config row, or `null` if the vault is not set up.
  Future<VaultConfig?> getVaultConfig() {
    return (select(vaultConfigs)..where((c) => c.id.equals(vaultConfigId)))
        .getSingleOrNull();
  }

  /// Creates or replaces the vault crypto config.
  Future<void> saveVaultConfig(VaultConfigsCompanion entry) =>
      into(vaultConfigs).insertOnConflictUpdate(entry);

  /// Watches all vault items, alphabetically by title (never decrypts).
  Stream<List<VaultItem>> watchVaultItems() {
    return (select(vaultItems)..orderBy([
          (v) => OrderingTerm(expression: v.title),
        ]))
        .watch();
  }

  Future<int> insertVaultItem(VaultItemsCompanion entry) =>
      into(vaultItems).insert(entry);

  Future<int> updateVaultItem(String id, VaultItemsCompanion entry) =>
      (update(vaultItems)..where((v) => v.id.equals(id))).write(entry);

  Future<int> deleteVaultItem(String id) =>
      (delete(vaultItems)..where((v) => v.id.equals(id))).go();
}

/// Primary key of the single [VaultConfigs] row.
const String vaultConfigId = 'singleton';
