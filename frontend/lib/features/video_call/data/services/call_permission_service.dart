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
  final bool requireVideo;
  final CallMediaPermissionState state;
  final PermissionStatus cameraStatus;
  final PermissionStatus microphoneStatus;

  const CallPermissionResult({
    required this.requireVideo,
    required this.state,
    required this.cameraStatus,
    required this.microphoneStatus,
  });

  bool get isGranted => state == CallMediaPermissionState.granted;

  bool get shouldOpenSettings =>
      state == CallMediaPermissionState.permanentlyDenied;

  String get userMessage {
    final mediaLabel = requireVideo
        ? 'La caméra et le microphone sont nécessaires pour la téléconsultation.'
        : 'Le microphone est nécessaire pour l’appel vocal.';
    final settingsLabel = requireVideo
        ? 'La caméra et le microphone sont nécessaires pour la téléconsultation. '
            'Autorisez-les depuis les paramètres de l’appareil.'
        : 'Le microphone est nécessaire pour l’appel vocal. '
            'Autorisez-le depuis les paramètres de l’appareil.';
    final restrictedLabel = requireVideo
        ? 'L’accès à la caméra ou au microphone est restreint sur cet appareil.'
        : 'L’accès au microphone est restreint sur cet appareil.';

    return switch (state) {
      CallMediaPermissionState.granted => '',
      CallMediaPermissionState.checking =>
        'Verification des autorisations en cours…',
      CallMediaPermissionState.denied => mediaLabel,
      CallMediaPermissionState.permanentlyDenied => settingsLabel,
      CallMediaPermissionState.restricted => restrictedLabel,
      CallMediaPermissionState.unknown => mediaLabel,
    };
  }
}

class CallPermissionService {
  static const List<Permission> _videoPermissions = <Permission>[
    Permission.camera,
    Permission.microphone,
  ];
  static const List<Permission> _audioPermissions = <Permission>[
    Permission.microphone,
  ];

  final CallPermissionGateway _gateway;

  const CallPermissionService({
    CallPermissionGateway gateway =
        const PermissionHandlerCallPermissionGateway(),
  }) : _gateway = gateway;

  Future<CallPermissionResult> checkMediaPermissions({
    bool requireVideo = true,
  }) async {
    final cameraStatus = requireVideo
        ? await _gateway.status(Permission.camera)
        : PermissionStatus.granted;
    final microphoneStatus = await _gateway.status(Permission.microphone);

    return _buildResult(
      cameraStatus,
      microphoneStatus,
      requireVideo: requireVideo,
    );
  }

  Future<CallPermissionResult> requestMediaPermissions({
    bool requireVideo = true,
  }) async {
    final statuses = await _gateway.request(
      requireVideo ? _videoPermissions : _audioPermissions,
    );
    final cameraStatus = requireVideo
        ? (statuses[Permission.camera] ?? PermissionStatus.denied)
        : PermissionStatus.granted;
    final microphoneStatus =
        statuses[Permission.microphone] ?? PermissionStatus.denied;

    return _buildResult(
      cameraStatus,
      microphoneStatus,
      requireVideo: requireVideo,
    );
  }

  Future<CallPermissionResult> ensureMediaPermissions({
    bool requestIfNeeded = true,
    bool requireVideo = true,
  }) async {
    final current = await checkMediaPermissions(requireVideo: requireVideo);
    if (current.isGranted || !requestIfNeeded) {
      return current;
    }

    return requestMediaPermissions(requireVideo: requireVideo);
  }

  Future<bool> openPermissionSettings() {
    return _gateway.openSettings();
  }

  CallPermissionResult _buildResult(
    PermissionStatus cameraStatus,
    PermissionStatus microphoneStatus, {
    required bool requireVideo,
  }) {
    final statuses = <PermissionStatus>[
      microphoneStatus,
      if (requireVideo) cameraStatus,
    ];

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
      requireVideo: requireVideo,
      state: state,
      cameraStatus: cameraStatus,
      microphoneStatus: microphoneStatus,
    );
  }
}
