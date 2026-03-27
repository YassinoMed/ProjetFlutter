library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../presentation/providers/appointment_providers.dart';

class BookingPage extends ConsumerStatefulWidget {
  final String doctorId;

  const BookingPage({super.key, required this.doctorId});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _availableSlots = const [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorSearchProvider);

    return Scaffold(
      body: SafeArea(
        child: doctorsAsync.when(
          data: (doctors) {
            DoctorEntity? doctor;
            for (final item in doctors) {
              if (item.userId == widget.doctorId) {
                doctor = item;
                break;
              }
            }

            return ListView(
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
                        'Prise de rendez-vous',
                        style: AppTheme.headlineSmall,
                      ),
                    ),
                    const Icon(Icons.verified_user_outlined,
                        color: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                if (doctor != null) _DoctorBookingCard(doctor: doctor),
                if (doctor != null) const SizedBox(height: 18),
                ClinicalSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choisissez une date', style: AppTheme.titleMedium),
                      const SizedBox(height: 12),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 90)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: AppTheme.titleSmall,
                          leftChevronIcon: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.neutralGray500,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: AppTheme.labelSmall.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                          weekendStyle: AppTheme.labelSmall.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle: AppTheme.bodyMedium,
                          weekendTextStyle: AppTheme.bodyMedium,
                          todayTextStyle: AppTheme.labelLarge.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                          selectedTextStyle: AppTheme.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ClinicalSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Créneaux disponibles', style: AppTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _availableSlots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSlot = slot;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 94,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.neutralWhite,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.neutralGray200,
                                ),
                                boxShadow: isSelected
                                    ? AppTheme.shadowPrimary
                                    : const [],
                              ),
                              child: Text(
                                slot,
                                textAlign: TextAlign.center,
                                style: AppTheme.labelLarge.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.neutralGray700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ClinicalSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Motif de consultation',
                          style: AppTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: douleur thoracique, suivi, contrôle annuel...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ClinicalSurface(
                  color: AppTheme.softColor(AppTheme.successColor, 0.08),
                  elevated: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Annulation gratuite jusqu’à 4h avant la consultation. '
                          'Passé ce délai, les frais et conditions du praticien peuvent s’appliquer.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_selectedDay != null && _selectedSlot != null)
                      ? _book
                      : null,
                  child: const Text('Confirmer le rendez-vous'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err', style: AppTheme.bodyMedium),
          ),
        ),
      ),
    );
  }

  Future<void> _book() async {
    final repository = ref.read(appointmentRepositoryProvider);

    final timeParts = _selectedSlot!.split(':');
    final appointmentDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    try {
      await repository.bookAppointment(
        doctorId: widget.doctorId,
        dateTime: appointmentDate,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous réservé avec succès')),
      );
      ref.invalidate(myAppointmentsProvider);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

class _DoctorBookingCard extends StatelessWidget {
  final DoctorEntity doctor;

  const _DoctorBookingCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
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
                Text(doctor.fullName, style: AppTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty ?? 'Médecine générale',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (doctor.rating > 0)
                      ClinicalStatusChip(
                        label:
                            '${doctor.rating.toStringAsFixed(1)} (${doctor.totalReviews})',
                        color: AppTheme.successColor,
                        icon: Icons.star_rounded,
                        compact: true,
                      ),
                    if (doctor.consultationFee != null)
                      ClinicalStatusChip(
                        label:
                            '${doctor.consultationFee}€ - ${doctor.consultationFee}€',
                        color: AppTheme.primaryColor,
                        compact: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
