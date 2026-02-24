/// Onboarding Page - First-time user walkthrough
/// CDC: Écran d'introduction avec choix de rôle
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    const _OnboardingSlide(
      icon: Icons.calendar_month_rounded,
      iconColor: AppTheme.appointmentColor,
      title: 'Prenez rendez-vous\nen quelques clics',
      description:
          'Trouvez le médecin idéal, consultez ses disponibilités '
          'et réservez votre créneau en temps réel.',
    ),
    const _OnboardingSlide(
      icon: Icons.chat_rounded,
      iconColor: AppTheme.chatColor,
      title: 'Messagerie\nsécurisée E2E',
      description:
          'Échangez avec votre médecin en toute confidentialité '
          'grâce au chiffrement de bout en bout.',
    ),
    const _OnboardingSlide(
      icon: Icons.videocam_rounded,
      iconColor: AppTheme.videoCallColor,
      title: 'Visioconsultation\nHD',
      description:
          'Consultez votre médecin à distance en vidéo HD, '
          'comme si vous y étiez.',
    ),
    const _OnboardingSlide(
      icon: Icons.shield_rounded,
      iconColor: AppTheme.recordsColor,
      title: 'Dossier médical\nsécurisé',
      description:
          'Vos données de santé sont chiffrées et protégées '
          'conformément au RGPD.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip Button ───────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    'Passer',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page View ─────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container with gradient
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                slide.iconColor.withValues(alpha: 0.1),
                                slide.iconColor.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 80,
                            color: slide.iconColor,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: AppTheme.headlineMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.neutralGray500,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Indicators + Button ───────────────────
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : AppTheme.neutralGray300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          context.go(AppRoutes.login);
                        }
                      },
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? 'Suivant'
                            : 'Commencer',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}
