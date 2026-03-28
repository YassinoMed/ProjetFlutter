import 'package:permission_handler/permission_handler.dart';

class CallPermissionService {
  const CallPermissionService();

  Future<void> ensureMediaPermissions() async {
    final statuses = await <Permission>[
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraStatus = statuses[Permission.camera];
    final microphoneStatus = statuses[Permission.microphone];

    if (cameraStatus != PermissionStatus.granted ||
        microphoneStatus != PermissionStatus.granted) {
      throw Exception(
        'Camera and microphone permissions are required for teleconsultation.',
      );
    }
  }
}
