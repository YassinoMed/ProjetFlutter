import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/appointment_providers.dart';
import '../../data/repositories/appointment_repository_impl.dart';

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

  final List<String> _availableSlots = [
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
    '16:30'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre RDV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sélectionnez une date', style: AppTheme.titleMedium),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: AppTheme.primaryLight, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: AppTheme.primaryColor, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false),
            ),
            const SizedBox(height: 24),
            Text('Sélectionnez un créneau', style: AppTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSlot = selected ? slot : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_selectedDay != null && _selectedSlot != null)
                  ? _bookAppointment
                  : null,
              child: const Text('Confirmer le rendez-vous'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final repository = ref.read(appointmentRepositoryProvider);

    // Combine day and slot
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous réservé avec succès !')),
        );
        Navigator.pop(context);
        final _ = ref.refresh(myAppointmentsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
