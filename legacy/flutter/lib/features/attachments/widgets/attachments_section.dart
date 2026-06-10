import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_provider.dart';
import '../attachment_service.dart';
import '../pdf_viewer_screen.dart';

/// A "Files" section for a client or project: lists attachments and attaches
/// new ones. Exactly one of [clientId] / [projectId] must be set.
class AttachmentsSection extends ConsumerWidget {
  const AttachmentsSection({super.key, this.clientId, this.projectId})
    : assert(
        clientId != null || projectId != null,
        'Attach to a client or a project',
      );

  final String? clientId;
  final String? projectId;

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(attachmentServiceProvider)
          .pickAndSave(clientId: clientId, projectId: projectId);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add the file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = clientId != null
        ? ref.watch(clientAttachmentsProvider(clientId!))
        : ref.watch(projectAttachmentsProvider(projectId!));
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Files', style: textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _attach(context, ref),
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Attach'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        attachmentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(
            'Files are available on-device.',
            style: textTheme.bodyMedium,
          ),
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No files yet. Attach a PDF, image, or document.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final attachment in items)
                  _AttachmentTile(attachment: attachment),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({required this.attachment});

  final Attachment attachment;

  IconData get _icon {
    final name = attachment.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.heic')) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final service = ref.read(attachmentServiceProvider);
    final navigator = Navigator.of(context);
    if (service.isPdf(attachment)) {
      final path = await service.absolutePath(attachment);
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PdfViewerScreen(path: path, title: attachment.fileName),
        ),
      );
    } else {
      await service.openExternally(attachment);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This permanently deletes ${attachment.fileName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(attachmentServiceProvider).delete(attachment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(_icon, color: AppColors.accent),
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formatBytes(attachment.sizeBytes)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: AppColors.textTertiary,
          tooltip: 'Delete file',
          onPressed: () => _delete(context, ref),
        ),
        onTap: () => _open(context, ref),
      ),
    );
  }
}
