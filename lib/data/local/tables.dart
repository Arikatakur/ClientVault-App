import 'package:drift/drift.dart';

/// A freelance/dev client. Plaintext on-device (no secrets stored here).
class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get company => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// `active | archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A project belonging to a [Clients] row. Optionally linked to a GitHub repo.
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get description => text().nullable()();

  /// `lead | active | paused | done`.
  TextColumn get status => text().withDefault(const Constant('lead'))();

  RealColumn get budget => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  // GitHub link (populated in a later version).
  TextColumn get repoId => text().nullable()();
  TextColumn get repoFullName => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// An encrypted secret (login, API key, account, note, card). Only [title] and
/// [type] are plaintext (for listing/search) — the sensitive payload lives in
/// [ciphertext], sealed with AES-256-GCM under the vault's data key (DEK).
class VaultItems extends Table {
  TextColumn get id => text()();

  /// `password | apiKey | account | note | card`.
  TextColumn get type => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();

  // Optional links to a client/project (plaintext).
  TextColumn get clientId => text().nullable().references(Clients, #id)();
  TextColumn get projectId => text().nullable().references(Projects, #id)();

  // AES-256-GCM sealed payload: ciphertext + unique nonce + integrity tag.
  BlobColumn get ciphertext => blob()();
  BlobColumn get nonce => blob()();
  BlobColumn get mac => blob()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row crypto configuration for the vault (envelope encryption). Stores
/// the KDF salt + parameters and the DEK wrapped by the password-derived KEK.
/// The master password itself is never persisted; a wrong password is detected
/// when GCM authentication of [wrappedDek] fails.
class VaultConfigs extends Table {
  TextColumn get id => text()();

  BlobColumn get kdfSalt => blob()();
  IntColumn get kdfMemory => integer()();
  IntColumn get kdfIterations => integer()();
  IntColumn get kdfParallelism => integer()();

  BlobColumn get wrappedDek => blob()();
  BlobColumn get wrappedDekNonce => blob()();
  BlobColumn get wrappedDekMac => blob()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A payment/invoice line on a [Projects] row. `status` is draft|sent|paid;
/// "overdue" is derived (unpaid and past [dueDate]) rather than stored, so it
/// stays accurate without a background job.
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// `draft | sent | paid`.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  DateTimeColumn get issuedDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get paidDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
