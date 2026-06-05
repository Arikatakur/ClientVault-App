import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No projects yet',
        message:
            'Projects you create for clients will live here — budgets, status, '
            'due dates, and linked GitHub repos.\n\nArriving in v0.2.0.',
      ),
    );
  }
}
