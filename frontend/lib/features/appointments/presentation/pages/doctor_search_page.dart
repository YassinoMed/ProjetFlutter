library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../domain/entities/doctor_entity.dart';
import '../providers/appointment_providers.dart';

class DoctorSearchPage extends ConsumerWidget {
  const DoctorSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorSearchProvider);
    final selectedSpeciality = ref.watch(doctorSpecialityFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: doctorsAsync.when(
          data: (doctors) {
            final specialities = doctors
                .map((doctor) => doctor.specialty)
                .whereType<String>()
                .where((specialty) => specialty.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(doctorSearchProvider);
                await ref.read(doctorSearchProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Recherche médecins',
                          style: AppTheme.headlineSmall,
                        ),
                      ),
                      const Icon(Icons.verified_user_outlined,
                          color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClinicalSearchField(
                    hintText: 'Rechercher un médecin ou une spécialité',
                    onChanged: (value) {
                      ref.read(doctorSearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'Tous',
                          selected: selectedSpeciality == null,
                          onTap: () => ref
                              .read(doctorSpecialityFilterProvider.notifier)
                              .state = null,
                        ),
                        const SizedBox(width: 8),
                        ...specialities.take(6).map((speciality) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: speciality,
                              selected: selectedSpeciality == speciality,
                              onTap: () => ref
                                  .read(doctorSpecialityFilterProvider.notifier)
                                  .state = speciality,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Médecins à proximité',
                          style: AppTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '${doctors.length} résultats'.toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.neutralGray400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (doctors.isEmpty)
                    const ClinicalEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun médecin trouvé',
                      message:
                          'Ajustez votre recherche ou vos filtres pour voir plus de praticiens.',
                    )
                  else
                    ...doctors.map((doctor) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DoctorCard(doctor: doctor),
                        )),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Erreur: $err',
              style: AppTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorEntity doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      onTap: () {
        context.push(AppRoutes.doctorDetail.replaceFirst(':id', doctor.userId));
      },
      child: Row(
        children: [
          ClinicalAvatar(
            name: doctor.fullName,
            imageUrl: doctor.avatarUrl,
            radius: 34,
            online: doctor.isAvailableForVideo,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.fullName, style: AppTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty ?? 'Médecine générale',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppTheme.neutralGray400,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        doctor.city ??
                            doctor.address ??
                            'Adresse non renseignée',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutralGray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 170,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      AppRoutes.doctorDetail.replaceFirst(':id', doctor.userId),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text('Voir disponibilités'),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (doctor.rating > 0)
                ClinicalStatusChip(
                  label: doctor.rating.toStringAsFixed(1),
                  color: AppTheme.successColor,
                  icon: Icons.star_rounded,
                  compact: true,
                ),
              const SizedBox(height: 8),
              if (doctor.consultationFee != null)
                Text(
                  '${doctor.consultationFee}€',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.neutralWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.neutralGray200,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: selected ? Colors.white : AppTheme.neutralGray600,
          ),
        ),
      ),
    );
  }
}
