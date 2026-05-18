import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../chat/domain/entities/chat_entities.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../prescriptions/domain/entities/prescription_entity.dart';
import '../../../waiting_room/domain/entities/waiting_room_session.dart';
import '../../domain/entities/doctor_dashboard_stats_model.dart';
import '../../domain/entities/patient_dashboard_model.dart';

class DashboardService {
  const DashboardService();

  PatientDashboardModel buildPatientDashboard({
    required List<Appointment> appointments,
    required List<MedicalDocument> documents,
    required List<Prescription> prescriptions,
    required List<Conversation> conversations,
  }) {
    final now = DateTime.now();
    final upcoming = appointments
        .where((appointment) =>
            appointment.dateTime.isAfter(now) &&
            appointment.status != AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final sortedDocuments = [...documents]..sort((a, b) {
        final left = a.documentDateUtc ?? a.processedAtUtc ?? DateTime(1900);
        final right = b.documentDateUtc ?? b.processedAtUtc ?? DateTime(1900);
        return right.compareTo(left);
      });
    final sortedPrescriptions = [...prescriptions]
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    final sortedConversations = [...conversations]
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return PatientDashboardModel(
      nextAppointment: upcoming.isEmpty ? null : upcoming.first,
      recentDocuments: sortedDocuments.take(3).toList(growable: false),
      recentPrescriptions: sortedPrescriptions.take(3).toList(growable: false),
      recentConversations: sortedConversations.take(3).toList(growable: false),
    );
  }

  DoctorDashboardStatsModel buildDoctorDashboard({
    required List<Appointment> appointments,
    required List<WaitingRoomSession> waitingPatients,
    required List<MedicalDocument> documents,
    required List<Conversation> conversations,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayAppointments = appointments.where((appointment) {
      final day = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      return day == today;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final documentsToReview = documents
        .where((document) =>
            document.isCompleted &&
            (document.summaryStatus.toUpperCase() == 'COMPLETED' ||
                document.urgencyLevel != null))
        .take(5)
        .toList(growable: false);

    return DoctorDashboardStatsModel(
      todayAppointments: todayAppointments,
      waitingPatients: waitingPatients,
      documentsToReview: documentsToReview,
      unreadMessagesCount: conversations.fold<int>(
        0,
        (total, conversation) => total + conversation.unreadCount,
      ),
      rescheduleRequestsCount: appointments
          .where((appointment) =>
              appointment.status == AppointmentStatus.pending &&
              appointment.notes?.toLowerCase().contains('report') == true)
          .length,
    );
  }
}
