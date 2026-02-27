import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';

final doctorSearchQueryProvider = StateProvider<String>((ref) => '');
final doctorSpecialityFilterProvider = StateProvider<String?>((ref) => null);

final doctorSearchProvider = FutureProvider<List<DoctorEntity>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final query = ref.watch(doctorSearchQueryProvider);
  final speciality = ref.watch(doctorSpecialityFilterProvider);

  return repository.searchDoctors(query: query, speciality: speciality);
});

final myAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getMyAppointments();
});
