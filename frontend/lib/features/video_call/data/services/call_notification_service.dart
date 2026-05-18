import '../../domain/entities/call_status.dart';

class CallNotificationService {
  const CallNotificationService();

  static const Duration defaultTimeout = Duration(seconds: 60);

  CallStatus timeoutStatus({required bool isIncoming}) {
    return CallStatus.unavailable;
  }

  String timeoutMessage({required bool isIncoming}) {
    return isIncoming
        ? 'Le médecin n’est plus disponible pour cet appel.'
        : 'Le patient n’a pas répondu dans le délai prévu.';
  }
}
