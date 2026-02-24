import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/appointment_providers.dart';
import '../../domain/entities/doctor_entity.dart';

class DoctorSearchPage extends ConsumerWidget {
  const DoctorSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un médecin'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(doctorSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou spécialité...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ),
      body: doctorsAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Center(child: Text('Aucun médecin trouvé'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return _DoctorCard(doctor: doctor);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              doctor.avatarUrl != null ? NetworkImage(doctor.avatarUrl!) : null,
          child: doctor.avatarUrl == null
              ? const Icon(Icons.person_rounded)
              : null,
        ),
        title: Text(doctor.fullName, style: AppTheme.titleMedium),
        subtitle: Text(doctor.speciality, style: AppTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // TODO: Navigate to doctor detail or booking
          context.push(
              AppRoutes.bookAppointment.replaceFirst(':doctorId', doctor.id));
        },
      ),
    );
  }
}
