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
