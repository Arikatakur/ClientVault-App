import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/id.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(ref.watch(databaseProvider));
});

/// Stores attachments as files under the app documents directory and records
/// their metadata in the database. Paths are stored *relative* to the docs
/// directory so they survive the iOS container path changing between launches.
class AttachmentService {
  AttachmentService(this._db);

  final AppDatabase _db;

  Future<String> _docsPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  /// Opens the file picker and, if a file is chosen, copies it into app storage
  /// and records it against [clientId] or [projectId]. Returns true if added.
  Future<bool> pickAndSave({String? clientId, String? projectId}) async {
    final result = await FilePicker.platform.pickFiles();
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return false;
    final picked = files.first;

    final id = newId();
    final relPath = p.join('attachments', '${id}_${picked.name}');
    final destPath = p.join(await _docsPath(), relPath);
    await Directory(p.dirname(destPath)).create(recursive: true);

    final srcPath = picked.path;
    final bytes = picked.bytes;
    if (srcPath != null) {
      await File(srcPath).copy(destPath);
    } else if (bytes != null) {
      await File(destPath).writeAsBytes(bytes);
    } else {
      return false;
    }

    await _db.insertAttachment(
      AttachmentsCompanion.insert(
        id: id,
        clientId: Value(clientId),
        projectId: Value(projectId),
        fileName: picked.name,
        storedPath: relPath,
        mimeType: Value(picked.extension),
        sizeBytes: picked.size,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  Future<String> absolutePath(Attachment attachment) async {
    return p.join(await _docsPath(), attachment.storedPath);
  }

  bool isPdf(Attachment attachment) {
    return attachment.mimeType?.toLowerCase() == 'pdf' ||
        attachment.fileName.toLowerCase().endsWith('.pdf');
  }

  /// Opens a non-PDF attachment in the system viewer (Quick Look on iOS).
  Future<void> openExternally(Attachment attachment) async {
    await OpenFilex.open(await absolutePath(attachment));
  }

  Future<void> delete(Attachment attachment) async {
    final file = File(await absolutePath(attachment));
    if (await file.exists()) await file.delete();
    await _db.deleteAttachment(attachment.id);
  }
}
