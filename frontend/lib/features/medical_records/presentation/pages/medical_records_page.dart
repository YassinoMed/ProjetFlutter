import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';

class MedicalRecordsPage extends ConsumerWidget {
  const MedicalRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier Médical')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRecordCategory(
            title: 'Consultations',
            icon: Icons.assignment_rounded,
            color: Colors.blue,
          ),
          _buildRecordCategory(
            title: 'Analyses & Labo',
            icon: Icons.science_rounded,
            color: Colors.purple,
          ),
          _buildRecordCategory(
            title: 'Ordonnances',
            icon: Icons.medication_rounded,
            color: Colors.green,
          ),
          _buildRecordCategory(
            title: 'Imagerie',
            icon: Icons.visibility_rounded,
            color: Colors.orange,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Ajouter un document'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildRecordCategory(
      {required String title, required IconData icon, required Color color}) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: AppTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
