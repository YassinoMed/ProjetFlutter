library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/clinical_ui.dart';
import '../router/app_routes.dart';
import '../theme/app_theme.dart';
import 'genui_providers.dart';

class GenUiPromptPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final String role;
  final String title;
  final String prompt;
  final Map<String, dynamic>? contextData;
  final Widget? fallback;
  final IconData icon;
  final bool autoLoad;
  final bool initiallyExpanded;
  final bool compact;
  final bool cache;
  final String? cacheKey;

  const GenUiPromptPanel({
    super.key,
    required this.sessionId,
    required this.role,
    required this.title,
    required this.prompt,
    this.contextData,
    this.fallback,
    this.icon = Icons.auto_awesome_rounded,
    this.autoLoad = false,
    this.initiallyExpanded = false,
    this.compact = false,
    this.cache = true,
    this.cacheKey,
  });

  @override
  ConsumerState<GenUiPromptPanel> createState() => _GenUiPromptPanelState();
}

class _GenUiPromptPanelState extends ConsumerState<GenUiPromptPanel> {
  late bool _expanded = widget.initiallyExpanded;

  GenUiSessionConfig get _config => GenUiSessionConfig(
        sessionId: widget.sessionId,
        role: widget.role,
      );

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(genUiSessionProvider(_config));
    final showBody = _expanded || controller.hasContent || controller.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClinicalSurface(
          padding: EdgeInsets.all(
            widget.compact ? AppTheme.spacingSm : AppTheme.spacingMd,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: widget.compact ? 34 : 40,
                    height: widget.compact ? 34 : 40,
                    decoration: BoxDecoration(
                      color: AppTheme.softColor(AppTheme.infoColor),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppTheme.infoColor,
                      size: widget.compact ? 18 : 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: widget.compact
                          ? AppTheme.titleSmall
                          : AppTheme.titleMedium,
                    ),
                  ),
                  if (controller.hasRequested)
                    IconButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => ref
                              .read(genUiSessionProvider(_config))
                              .regenerate(
                                prompt: widget.prompt,
                                context: widget.contextData,
                                useCache: widget.cache,
                                cacheKey: widget.cacheKey,
                              ),
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Actualiser',
                    ),
                  IconButton(
                    onPressed: () {
                      setState(() => _expanded = !_expanded);
                      if (!_expanded) return;
                      _generate();
                    },
                    icon: Icon(
                      showBody
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    tooltip: showBody ? 'Réduire' : 'Ouvrir',
                  ),
                ],
              ),
              if (!controller.hasRequested && !controller.isLoading) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _expanded = true);
                      _generate();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Générer'),
                  ),
                ),
              ],
              if (controller.isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (controller.error != null && !controller.hasContent) ...[
                const SizedBox(height: 12),
                _GenUiErrorText(message: controller.error!),
              ],
            ],
          ),
        ),
        if (showBody) ...[
          const SizedBox(height: 10),
          GenUiSurfaceStack(
            controller: controller,
            role: widget.role,
            fallback: widget.fallback,
          ),
        ],
      ],
    );
  }

  Future<void> _generate() {
    return ref.read(genUiSessionProvider(_config)).generate(
          prompt: widget.prompt,
          context: widget.contextData,
          useCache: widget.cache,
          cacheKey: widget.cacheKey,
        );
  }
}

class GenUiSurfaceStack extends StatelessWidget {
  final GenUiSessionController controller;
  final String role;
  final Widget? fallback;

  const GenUiSurfaceStack({
    super.key,
    required this.controller,
    required this.role,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.hasContent) {
      return fallback ?? const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...controller.surfaceIds.map(
          (surfaceId) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              surfaceContext: controller.surfaceController.contextFor(
                surfaceId,
              ),
              actionDelegate: MediConnectGenUiActionDelegate(role: role),
              defaultBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
        if (controller.generatedText.isNotEmpty)
          _GenUiTextSurface(text: controller.generatedText),
      ],
    );
  }
}

class MediConnectGenUiActionDelegate implements ActionDelegate {
  final String role;

  const MediConnectGenUiActionDelegate({required this.role});

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
        buildWidget,
  ) {
    if (event is! UserActionEvent) return false;

    if (event.name == 'appointmentTapped') {
      final appointmentId = event.context['appointmentId']?.toString();
      if (appointmentId == null || appointmentId.isEmpty) return false;

      final route = role == 'doctor'
          ? AppRoutes.doctorAppointmentDetail
          : AppRoutes.appointmentDetail;
      context.push(route.replaceFirst(':id', appointmentId));
      return true;
    }

    if (event.name != 'buttonAction') return false;

    final action = event.context['action']?.toString();
    if (action == null || action.isEmpty) return false;

    final route = _routeForAction(action);
    if (route == null) return false;

    if (_isShellRoute(route)) {
      context.go(route);
    } else {
      context.push(route);
    }
    return true;
  }

  String? _routeForAction(String action) {
    if (action.startsWith('/')) return action;

    final normalized =
        action.replaceAll(RegExp(r'[\s_-]+'), '').trim().toLowerCase();

    return switch (normalized) {
      'appointments' || 'openappointments' || 'rdv' => _appointmentsRoute(),
      'chat' || 'messages' || 'openchat' => _chatRoute(),
      'profile' || 'openprofile' => _profileRoute(),
      'settings' || 'preferences' || 'openpreferences' => _profileRoute(),
      'gdpr' || 'rgpd' || 'privacy' => AppRoutes.gdprSettings,
      'devices' ||
      'trusteddevices' ||
      'securitydevices' =>
        AppRoutes.trustedDevices,
      'notifications' => AppRoutes.notifications,
      'records' || 'medicalrecords' || 'dossier' => AppRoutes.patientRecords,
      'documents' => AppRoutes.documents,
      'doctorsearch' ||
      'finddoctor' ||
      'bookappointment' =>
        AppRoutes.doctorSearch,
      'aichat' || 'assistant' || 'openassistant' => AppRoutes.doctorAiChat,
      _ => null,
    };
  }

  String _appointmentsRoute() {
    return switch (role) {
      'doctor' => AppRoutes.doctorAppointments,
      'secretary' => AppRoutes.secretaryAppointments,
      _ => AppRoutes.patientAppointments,
    };
  }

  String _chatRoute() {
    return role == 'doctor' ? AppRoutes.doctorChat : AppRoutes.patientChat;
  }

  String _profileRoute() {
    return switch (role) {
      'doctor' => AppRoutes.doctorProfile,
      'secretary' => AppRoutes.secretaryProfile,
      _ => AppRoutes.patientProfile,
    };
  }

  bool _isShellRoute(String route) {
    return route == AppRoutes.patientHome ||
        route == AppRoutes.patientAppointments ||
        route == AppRoutes.patientChat ||
        route == AppRoutes.patientProfile ||
        route == AppRoutes.doctorHome ||
        route == AppRoutes.doctorAppointments ||
        route == AppRoutes.doctorChat ||
        route == AppRoutes.doctorProfile ||
        route == AppRoutes.secretaryHome ||
        route == AppRoutes.secretaryAppointments ||
        route == AppRoutes.secretaryProfile;
  }
}

class _GenUiTextSurface extends StatelessWidget {
  final String text;

  const _GenUiTextSurface({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      child: Text(
        text,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.neutralGray600,
        ),
      ),
    );
  }
}

class _GenUiErrorText extends StatelessWidget {
  final String message;

  const _GenUiErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: AppTheme.errorColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }
}
