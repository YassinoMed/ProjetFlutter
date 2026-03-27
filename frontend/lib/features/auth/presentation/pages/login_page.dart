/// Login Page - aligned with dedicated Figma/Login mockup
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showBiometricButton = false;
  bool _biometricAvailable = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_email');
    if (lastEmail != null) {
      _emailController.text = lastEmail;
    }

    final biometricAvailableAsync = ref.read(isBiometricAvailableProvider);
    final biometricEnabled = ref.read(isBiometricEnabledProvider);

    biometricAvailableAsync.whenData((available) {
      if (!mounted) return;

      setState(() {
        _biometricAvailable = available;
        _showBiometricButton = available && biometricEnabled;
      });

      if (available && biometricEnabled) {
        _handleBiometricLogin();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.login(
      identifier: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.when(
      data: (state) async {
        if (!state.isAuthenticated) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_email', _emailController.text.trim());

        if (!mounted) return;
        _redirectForRole(state.user?.role);
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      },
    );
  }

  Future<void> _handleBiometricLogin() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.loginWithBiometric();

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.maybeWhen(
      data: (state) {
        if (state.isAuthenticated) {
          _redirectForRole(state.user?.role);
        }
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      },
      orElse: () {},
    );
  }

  void _redirectForRole(String? role) {
    if (role == AppConstants.roleDoctor) {
      context.go(AppRoutes.doctorHome);
      return;
    }
    if (role == AppConstants.roleSecretary) {
      context.go(AppRoutes.secretaryHome);
      return;
    }
    context.go(AppRoutes.patientHome);
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final biometricEnabled = ref.watch(isBiometricEnabledProvider);
    final biometricAvailableAsync = ref.watch(isBiometricAvailableProvider);

    biometricAvailableAsync.whenData((available) {
      final shouldShow = available && biometricEnabled;
      if (_biometricAvailable != available ||
          _showBiometricButton != shouldShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _biometricAvailable = available;
            _showBiometricButton = shouldShow;
          });
        });
      }
    });

    return Scaffold(
      body: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.neutralGray50,
        child: Stack(
          children: [
            _DecorativeBackground(isDark: isDark),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: IntrinsicHeight(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Icon(
                                      isDark
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      size: 22,
                                      color: isDark
                                          ? AppTheme.secondaryLight
                                              .withValues(alpha: 0.85)
                                          : AppTheme.neutralGray300,
                                    ),
                                  ),
                                  const Spacer(),
                                  _BrandHeader(isDark: isDark),
                                  const SizedBox(height: 34),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _FormLabel(
                                          label: 'Email ou Telephone',
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 8),
                                        _LoginField(
                                          isDark: isDark,
                                          controller: _emailController,
                                          hintText:
                                              'nom@etablissement.fr ou +216 20 000 000',
                                          prefixIcon:
                                              Icons.mail_outline_rounded,
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                          validator: Validators.emailOrPhone,
                                        ),
                                        const SizedBox(height: 18),
                                        _FormLabel(
                                          label: 'Mot de Passe',
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 8),
                                        _LoginField(
                                          isDark: isDark,
                                          controller: _passwordController,
                                          hintText: '••••••••',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Le mot de passe est requis';
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (_) =>
                                              _handleLogin(),
                                          suffix: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: isDark
                                                  ? AppTheme.secondaryLight
                                                      .withValues(alpha: 0.55)
                                                  : AppTheme.neutralGray400,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {},
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Mot de passe oublié ?',
                                              style:
                                                  AppTheme.labelSmall.copyWith(
                                                color: isDark
                                                    ? AppTheme.secondaryLight
                                                    : AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        SizedBox(
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed:
                                                isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 0,
                                              shadowColor: AppTheme.primaryColor
                                                  .withValues(alpha: 0.24),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    'Se connecter',
                                                    style: AppTheme.titleMedium
                                                        .copyWith(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 56,
                                          child: OutlinedButton.icon(
                                            onPressed: (_showBiometricButton ||
                                                        _biometricAvailable) &&
                                                    !isLoading
                                                ? _handleBiometricLogin
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.05)
                                                  : AppTheme.neutralGray200,
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.10)
                                                    : Colors.transparent,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              foregroundColor: isDark
                                                  ? Colors.white
                                                  : AppTheme.neutralGray900,
                                              disabledForegroundColor: isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.32)
                                                  : AppTheme.neutralGray400,
                                            ),
                                            icon: Icon(
                                              isDark
                                                  ? Icons.fingerprint_rounded
                                                  : Icons
                                                      .face_retouching_natural_rounded,
                                              size: 20,
                                            ),
                                            label: Text(
                                              isDark
                                                  ? 'Continuer par biométrie'
                                                  : 'Continuer avec FaceID',
                                              style:
                                                  AppTheme.titleSmall.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _SecurityBadge(isDark: isDark),
                                  const SizedBox(height: 18),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.register),
                                    child: Text(
                                      'Créer un compte professionnel',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppTheme.secondaryLight
                                                .withValues(alpha: 0.92)
                                            : AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'V2.0 STABLE',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.20)
                                            : AppTheme.neutralGray400
                                                .withValues(alpha: 0.9),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isDark;

  const _BrandHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.72),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppTheme.neutralGray200.withValues(alpha: 0.55),
            ),
            boxShadow: isDark ? AppTheme.shadowMd : AppTheme.shadowSm,
          ),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M+',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Bienvenue',
          textAlign: TextAlign.center,
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 56,
            height: 0.95,
            letterSpacing: -1.4,
            color: isDark ? Colors.white : AppTheme.neutralGray900,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ACCÈS\nSÉCURISÉ\nPRATICIEN',
          textAlign: TextAlign.center,
          style: AppTheme.labelLarge.copyWith(
            color: isDark
                ? AppTheme.secondaryLight.withValues(alpha: 0.58)
                : AppTheme.neutralGray500.withValues(alpha: 0.85),
            letterSpacing: 2.4,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  const _LoginField({
    required this.isDark,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffix,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.neutralGray100;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : Colors.transparent;
    final iconColor = isDark
        ? AppTheme.secondaryLight.withValues(alpha: 0.50)
        : AppTheme.neutralGray400;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTheme.bodyLarge.copyWith(
        color: isDark ? Colors.white : AppTheme.neutralGray800,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTheme.bodyLarge.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.20)
              : AppTheme.neutralGray400,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(prefixIcon, color: iconColor),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? AppTheme.secondaryLight.withValues(alpha: 0.30)
                : AppTheme.primaryColor.withValues(alpha: 0.20),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final bool isDark;

  const _SecurityBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.successColor.withValues(alpha: 0.10)
            : AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: isDark
              ? AppTheme.successColor.withValues(alpha: 0.22)
              : AppTheme.successColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.enhanced_encryption_rounded,
            size: 18,
            color: isDark ? const Color(0xFF3CE36A) : AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          Text(
            'CHIFFREMENT E2E ACTIF',
            style: AppTheme.labelSmall.copyWith(
              color: isDark ? const Color(0xFF3CE36A) : AppTheme.successColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  final bool isDark;

  const _DecorativeBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -70,
            child: _GlowBlob(
              size: 240,
              color: isDark
                  ? AppTheme.primaryLight.withValues(alpha: 0.18)
                  : AppTheme.primaryLight.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _GlowBlob(
              size: 220,
              color: isDark
                  ? AppTheme.successColor.withValues(alpha: 0.10)
                  : AppTheme.secondaryLight.withValues(alpha: 0.26),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _FormLabel({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: AppTheme.labelLarge.copyWith(
          color: isDark
              ? AppTheme.secondaryLight.withValues(alpha: 0.60)
              : AppTheme.neutralGray600,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
