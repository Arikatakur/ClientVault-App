import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();

/// Generates a new random UUID v4 string, used for entity primary keys.
String newId() => _uuid.v4();
