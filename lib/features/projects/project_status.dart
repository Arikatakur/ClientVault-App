import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The lifecycle of a project. The [value] is what gets persisted in the
/// database `status` column; [label] and [color] drive the UI.
enum ProjectStatus {
  lead('lead', 'Lead', AppColors.textTertiary),
  active('active', 'Active', AppColors.accent),
  paused('paused', 'Paused', AppColors.warning),
  done('done', 'Done', AppColors.success);

  const ProjectStatus(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  /// Resolves a stored status string, defaulting to [ProjectStatus.lead] for
  /// any unexpected value so the UI never breaks on legacy data.
  static ProjectStatus fromValue(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.lead,
    );
  }
}
