import 'package:equatable/equatable.dart';

import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../waiting_room/domain/entities/waiting_room_session.dart';

class DoctorDashboardStatsModel extends Equatable {
  final List<Appointment> todayAppointments;
  final List<WaitingRoomSession> waitingPatients;
  final List<MedicalDocument> documentsToReview;
  final int unreadMessagesCount;
  final int rescheduleRequestsCount;

  const DoctorDashboardStatsModel({
    this.todayAppointments = const [],
    this.waitingPatients = const [],
    this.documentsToReview = const [],
    this.unreadMessagesCount = 0,
    this.rescheduleRequestsCount = 0,
  });

  int get upcomingTeleconsultationsCount {
    final now = DateTime.now();
    return todayAppointments
        .where((appointment) =>
            appointment.type == AppointmentType.video &&
            appointment.dateTime.isAfter(now))
        .length;
  }

  @override
  List<Object?> get props => [
        todayAppointments,
        waitingPatients,
        documentsToReview,
        unreadMessagesCount,
        rescheduleRequestsCount,
      ];
}
