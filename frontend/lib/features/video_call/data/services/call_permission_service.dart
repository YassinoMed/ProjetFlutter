import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class CallPermissionGateway {
  const CallPermissionGateway();

  Future<PermissionStatus> status(Permission permission);

  Future<Map<Permission, PermissionStatus>> request(
      List<Permission> permissions);

  Future<bool> openSettings();
}

class PermissionHandlerCallPermissionGateway implements CallPermissionGateway {
  const PermissionHandlerCallPermissionGateway();

  @override
  Future<PermissionStatus> status(Permission permission) {
    return permission.status;
  }

  @override
  Future<Map<Permission, PermissionStatus>> request(
      List<Permission> permissions) {
    return permissions.request();
  }

  @override
  Future<bool> openSettings() {
    return openAppSettings();
  }
}

class CallPermissionResult {
  final CallMediaPermissionState state;
  final PermissionStatus cameraStatus;
  final PermissionStatus microphoneStatus;

  const CallPermissionResult({
    required this.state,
    required this.cameraStatus,
    required this.microphoneStatus,
  });

  bool get isGranted => state == CallMediaPermissionState.granted;

  bool get shouldOpenSettings =>
      state == CallMediaPermissionState.permanentlyDenied;

  String get userMessage {
    return switch (state) {
      CallMediaPermissionState.granted => '',
      CallMediaPermissionState.checking =>
        'Verification des autorisations en cours…',
      CallMediaPermissionState.denied =>
        'La caméra et le microphone sont nécessaires pour la téléconsultation.',
      CallMediaPermissionState.permanentlyDenied =>
        'La caméra et le microphone sont nécessaires pour la téléconsultation. '
            'Autorisez-les depuis les paramètres de l’appareil.',
      CallMediaPermissionState.restricted =>
        'L’accès à la caméra ou au microphone est restreint sur cet appareil.',
      CallMediaPermissionState.unknown =>
        'La caméra et le microphone sont nécessaires pour la téléconsultation.',
    };
  }
}

class CallPermissionService {
  static const List<Permission> _requiredPermissions = <Permission>[
    Permission.camera,
    Permission.microphone,
  ];

  final CallPermissionGateway _gateway;

  const CallPermissionService({
    CallPermissionGateway gateway =
        const PermissionHandlerCallPermissionGateway(),
  }) : _gateway = gateway;

  Future<CallPermissionResult> checkMediaPermissions() async {
    final cameraStatus = await _gateway.status(Permission.camera);
    final microphoneStatus = await _gateway.status(Permission.microphone);

    return _buildResult(cameraStatus, microphoneStatus);
  }

  Future<CallPermissionResult> requestMediaPermissions() async {
    final statuses = await _gateway.request(_requiredPermissions);
    final cameraStatus = statuses[Permission.camera] ?? PermissionStatus.denied;
    final microphoneStatus =
        statuses[Permission.microphone] ?? PermissionStatus.denied;

    return _buildResult(cameraStatus, microphoneStatus);
  }

  Future<CallPermissionResult> ensureMediaPermissions({
    bool requestIfNeeded = true,
  }) async {
    final current = await checkMediaPermissions();
    if (current.isGranted || !requestIfNeeded) {
      return current;
    }

    return requestMediaPermissions();
  }

  Future<bool> openPermissionSettings() {
    return _gateway.openSettings();
  }

  CallPermissionResult _buildResult(
    PermissionStatus cameraStatus,
    PermissionStatus microphoneStatus,
  ) {
    final statuses = <PermissionStatus>[cameraStatus, microphoneStatus];

    final state = statuses.every((status) => status == PermissionStatus.granted)
        ? CallMediaPermissionState.granted
        : statuses.any(
            (status) => status == PermissionStatus.permanentlyDenied,
          )
            ? CallMediaPermissionState.permanentlyDenied
            : statuses.any((status) => status == PermissionStatus.restricted)
                ? CallMediaPermissionState.restricted
                : CallMediaPermissionState.denied;

    return CallPermissionResult(
      state: state,
      cameraStatus: cameraStatus,
      microphoneStatus: microphoneStatus,
    );
  }
}
