import 'package:equatable/equatable.dart';

import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../chat/domain/entities/chat_entities.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../prescriptions/domain/entities/prescription_entity.dart';

class PatientDashboardModel extends Equatable {
  final Appointment? nextAppointment;
  final List<MedicalDocument> recentDocuments;
  final List<Prescription> recentPrescriptions;
  final List<Conversation> recentConversations;

  const PatientDashboardModel({
    this.nextAppointment,
    this.recentDocuments = const [],
    this.recentPrescriptions = const [],
    this.recentConversations = const [],
  });

  bool get canJoinNextTeleconsultation {
    final appointment = nextAppointment;
    if (appointment == null || appointment.type != AppointmentType.video) {
      return false;
    }

    final now = DateTime.now();
    final startsIn = appointment.dateTime.difference(now);
    final endsAt = appointment.dateTime.add(
      Duration(minutes: appointment.durationMinutes + 15),
    );

    return startsIn <= const Duration(minutes: 15) && endsAt.isAfter(now);
  }

  @override
  List<Object?> get props => [
        nextAppointment,
        recentDocuments,
        recentPrescriptions,
        recentConversations,
      ];
}
