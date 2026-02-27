import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';

class DoctorHomePage extends ConsumerWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dr. ${user?.name ?? ''}',
                style: AppTheme.headlineSmall
                    .copyWith(color: AppTheme.neutralWhite),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Consultations du jour', style: AppTheme.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.doctorAppointments),
                        child: const Text('Planning complet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mockup of today's appointments for doctor
                  _buildAppointmentQueue(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        const _StatCard(
          title: 'Aujourd\'hui',
          value: '5',
          icon: Icons.people_rounded,
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        const _StatCard(
          title: 'En attente',
          value: '2',
          icon: Icons.pending_actions_rounded,
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Messages',
          value: '3',
          icon: Icons.chat_rounded,
          color: Colors.green,
          onTap: () => context.go(AppRoutes.doctorChat),
        ),
      ],
    );
  }

  Widget _buildAppointmentQueue(BuildContext context) {
    // Scaffold UI for appointments
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Text('MA')),
            title: const Text('Mohammed Alami'),
            subtitle: const Text('10:00 - Consultation vidéo'),
            trailing: IconButton(
              icon: const Icon(Icons.videocam_rounded, color: Colors.purple),
              onPressed: () {},
            ),
            onTap: () {},
          ),
        ),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('K')),
            title: Text('Karima', style: TextStyle(color: Colors.grey)),
            subtitle:
                Text('09:00 - Terminé', style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.check_circle_rounded, color: Colors.green),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
