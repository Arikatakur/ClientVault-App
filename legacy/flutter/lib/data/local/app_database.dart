import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The on-device SQLite database. `driftDatabase` opens a native, file-backed
/// database on iOS/Android (and desktop); a test executor can be injected.
@DriftDatabase(
  tables: [Clients, Projects, VaultItems, VaultConfigs, Payments, Attachments],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'clientvault'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Additive migrations; existing rows are always preserved.
      if (from < 2) {
        await m.createTable(vaultItems);
        await m.createTable(vaultConfigs);
      }
      if (from < 3) {
        await m.createTable(payments);
      }
      if (from < 4) {
        await m.addColumn(payments, payments.paidAmount);
        // Treat already-"paid" rows as fully paid under the new partial model.
        await customStatement(
          "UPDATE payments SET paid_amount = amount WHERE status = 'paid'",
        );
      }
      if (from < 5) {
        await m.createTable(attachments);
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

  /// Deletes a client with all of its projects and their payments in a single
  /// transaction, so no rows are left orphaned.
  Future<void> deleteClient(String id) {
    return transaction(() async {
      final projectIds =
          await (selectOnly(projects)
                ..addColumns([projects.id])
                ..where(projects.clientId.equals(id)))
              .map((row) => row.read(projects.id)!)
              .get();
      if (projectIds.isNotEmpty) {
        await (delete(
          payments,
        )..where((p) => p.projectId.isIn(projectIds))).go();
      }
      await (delete(
            attachments,
          )..where((a) => a.clientId.equals(id) | a.projectId.isIn(projectIds)))
          .go();
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
    return (select(
      projects,
    )..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertProject(ProjectsCompanion entry) =>
      into(projects).insert(entry);

  /// Applies a partial update to the project with [id].
  Future<int> updateProject(String id, ProjectsCompanion entry) =>
      (update(projects)..where((p) => p.id.equals(id))).write(entry);

  /// Deletes a project with its payments and attachments in one transaction.
  Future<void> deleteProject(String id) {
    return transaction(() async {
      await (delete(payments)..where((p) => p.projectId.equals(id))).go();
      await (delete(attachments)..where((a) => a.projectId.equals(id))).go();
      await (delete(projects)..where((p) => p.id.equals(id))).go();
    });
  }

  // --- Vault -----------------------------------------------------------------

  /// The single vault crypto-config row, or `null` if the vault is not set up.
  Future<VaultConfig?> getVaultConfig() {
    return (select(
      vaultConfigs,
    )..where((c) => c.id.equals(vaultConfigId))).getSingleOrNull();
  }

  /// Creates or replaces the vault crypto config.
  Future<void> saveVaultConfig(VaultConfigsCompanion entry) =>
      into(vaultConfigs).insertOnConflictUpdate(entry);

  /// Watches all vault items, alphabetically by title (never decrypts).
  Stream<List<VaultItem>> watchVaultItems() {
    return (select(
      vaultItems,
    )..orderBy([(v) => OrderingTerm(expression: v.title)])).watch();
  }

  /// Watches the vault items linked to one client (titles only).
  Stream<List<VaultItem>> watchVaultItemsForClient(String clientId) {
    return (select(vaultItems)
          ..where((v) => v.clientId.equals(clientId))
          ..orderBy([(v) => OrderingTerm(expression: v.title)]))
        .watch();
  }

  /// Watches the vault items linked to one project (titles only).
  Stream<List<VaultItem>> watchVaultItemsForProject(String projectId) {
    return (select(vaultItems)
          ..where((v) => v.projectId.equals(projectId))
          ..orderBy([(v) => OrderingTerm(expression: v.title)]))
        .watch();
  }

  Future<int> insertVaultItem(VaultItemsCompanion entry) =>
      into(vaultItems).insert(entry);

  Future<int> updateVaultItem(String id, VaultItemsCompanion entry) =>
      (update(vaultItems)..where((v) => v.id.equals(id))).write(entry);

  Future<int> deleteVaultItem(String id) =>
      (delete(vaultItems)..where((v) => v.id.equals(id))).go();

  // --- Payments --------------------------------------------------------------

  /// Watches every payment (used for the dashboard outstanding total).
  Stream<List<Payment>> watchPayments() => select(payments).watch();

  /// One-shot read of every payment (used by the reminder scheduler).
  Future<List<Payment>> getAllPayments() => select(payments).get();

  /// One-shot read of every project (used by the reminder scheduler).
  Future<List<Project>> getAllProjects() => select(projects).get();

  /// Watches the payments for one project, newest issue/created first.
  Stream<List<Payment>> watchPaymentsForProject(String projectId) {
    return (select(payments)
          ..where((p) => p.projectId.equals(projectId))
          ..orderBy([
            (p) =>
                OrderingTerm(expression: p.issuedDate, mode: OrderingMode.desc),
            (p) =>
                OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insertPayment(PaymentsCompanion entry) =>
      into(payments).insert(entry);

  Future<int> updatePayment(String id, PaymentsCompanion entry) =>
      (update(payments)..where((p) => p.id.equals(id))).write(entry);

  Future<int> deletePayment(String id) =>
      (delete(payments)..where((p) => p.id.equals(id))).go();

  // --- Attachments -----------------------------------------------------------

  Stream<List<Attachment>> watchAttachmentsForClient(String clientId) {
    return (select(attachments)
          ..where((a) => a.clientId.equals(clientId))
          ..orderBy([
            (a) =>
                OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<Attachment>> watchAttachmentsForProject(String projectId) {
    return (select(attachments)
          ..where((a) => a.projectId.equals(projectId))
          ..orderBy([
            (a) =>
                OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insertAttachment(AttachmentsCompanion entry) =>
      into(attachments).insert(entry);

  Future<int> deleteAttachment(String id) =>
      (delete(attachments)..where((a) => a.id.equals(id))).go();

  // --- Backup ------------------------------------------------------------------

  /// One-shot dump of every table for the encrypted backup. Attachment file
  /// bytes are not part of backups (yet), so attachment rows are excluded too.
  Future<BackupRows> exportAllRows() async => BackupRows(
    clients: await select(clients).get(),
    projects: await select(projects).get(),
    payments: await select(payments).get(),
    vaultItems: await select(vaultItems).get(),
    vaultConfig: await getVaultConfig(),
  );

  /// Replaces the entire database with [rows] in one transaction (backup
  /// import). Attachment records are cleared — their files are orphaned by a
  /// restore and are wiped separately by the backup service.
  Future<void> replaceAllRows(BackupRows rows) {
    return transaction(() async {
      await delete(attachments).go();
      await delete(payments).go();
      await delete(vaultItems).go();
      await delete(projects).go();
      await delete(clients).go();
      await delete(vaultConfigs).go();
      await batch((b) {
        b.insertAll(clients, rows.clients);
        b.insertAll(projects, rows.projects);
        b.insertAll(payments, rows.payments);
        b.insertAll(vaultItems, rows.vaultItems);
        if (rows.vaultConfig != null) {
          b.insert(vaultConfigs, rows.vaultConfig!);
        }
      });
    });
  }
}

/// Every row a backup carries, in plain Drift data classes.
class BackupRows {
  const BackupRows({
    required this.clients,
    required this.projects,
    required this.payments,
    required this.vaultItems,
    this.vaultConfig,
  });

  final List<Client> clients;
  final List<Project> projects;
  final List<Payment> payments;
  final List<VaultItem> vaultItems;
  final VaultConfig? vaultConfig;
}

/// Primary key of the single [VaultConfigs] row.
const String vaultConfigId = 'singleton';
