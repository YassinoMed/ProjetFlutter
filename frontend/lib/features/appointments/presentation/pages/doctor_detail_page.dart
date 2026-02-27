import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:mediconnect_pro/shared/widgets/error_display.dart';

class DoctorDetailPage extends ConsumerWidget {
  final String doctorId;
  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We would probably want a specific provider to get a doctor by ID
    // For now we will find them in the search list or show loading
    final doctorsAsync = ref.watch(doctorSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.neutralGray900 : Colors.grey[50],
      body: doctorsAsync.when(
        data: (doctors) {
          final doctor = doctors.cast<dynamic>().firstWhere(
                (d) => d.userId == doctorId,
                orElse: () => null,
              );

          if (doctor == null) {
            return const Scaffold(
              body: Center(child: Text('Médecin introuvable')),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: doctor.avatarUrl != null
                            ? Image.network(doctor.avatarUrl!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter)
                            : const Icon(Icons.person,
                                size: 120, color: AppTheme.primaryColor),
                      ),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    doctor.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              doctor.specialty ?? 'Généraliste',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          if (doctor.rating != null)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                if (doctor.totalReviews != null)
                                  Text(
                                    ' (${doctor.totalReviews})',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info Grid
                      Row(
                        children: [
                          _InfoCard(
                            icon: Icons.location_on_rounded,
                            title: 'Lieu',
                            subtitle: doctor.city ?? 'Cabinet',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _InfoCard(
                            icon: Icons.payments_rounded,
                            title: 'Tarif',
                            subtitle: doctor.consultationFee != null
                                ? '${doctor.consultationFee} MAD'
                                : 'Secteur 1',
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (doctor.isAvailableForVideo)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.videocam_rounded,
                                  color: Colors.purple),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Propose la téléconsultation (WebRTC chiffré)',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      Text('À propos', style: AppTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        doctor.bio ??
                            'Aucune description fournie pour le moment.',
                        style: TextStyle(
                          height: 1.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for fab
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.refresh(doctorSearchProvider),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () {
              context.push(AppRoutes.bookAppointment
                  .replaceFirst(':doctorId', doctorId));
            },
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Prendre rendez-vous'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
