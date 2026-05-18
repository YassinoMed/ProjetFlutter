import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../prescriptions/presentation/providers/prescription_providers.dart';
import '../../../waiting_room/domain/entities/waiting_room_session.dart';
import '../../../waiting_room/presentation/providers/waiting_room_providers.dart';
import '../../data/services/dashboard_service.dart';
import '../../domain/entities/doctor_dashboard_stats_model.dart';
import '../../domain/entities/patient_dashboard_model.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return const DashboardService();
});

final patientDashboardProvider = Provider<PatientDashboardModel>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  final user = ref.watch(currentUserProvider);
  final appointments =
      ref.watch(myAppointmentsProvider).valueOrNull ?? const [];
  final documents = ref.watch(documentsProvider).valueOrNull ?? const [];
  final prescriptions = ref.watch(prescriptionStoreProvider);
  final conversations =
      ref.watch(conversationsProvider).valueOrNull ?? const [];

  return service.buildPatientDashboard(
    appointments: appointments,
    documents: documents
        .where((document) =>
            user == null ||
            document.patientUserId == user.id ||
            document.uploadedByUserId == user.id)
        .toList(growable: false),
    prescriptions: prescriptions
        .where(
            (prescription) => user == null || prescription.patientId == user.id)
        .toList(growable: false),
    conversations: conversations,
  );
});

final doctorDashboardProvider = Provider<DoctorDashboardStatsModel>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  final user = ref.watch(currentUserProvider);
  final appointments =
      ref.watch(myAppointmentsProvider).valueOrNull ?? const [];
  final documents = ref.watch(documentsProvider).valueOrNull ?? const [];
  final conversations =
      ref.watch(conversationsProvider).valueOrNull ?? const [];
  final List<WaitingRoomSession> waitingPatients = user == null
      ? const <WaitingRoomSession>[]
      : ref.watch(waitingPatientsForDoctorProvider(user.id));

  return service.buildDoctorDashboard(
    appointments: appointments,
    waitingPatients: waitingPatients,
    documents: documents
        .where((document) => user == null || document.doctorUserId == user.id)
        .toList(growable: false),
    conversations: conversations,
  );
});
