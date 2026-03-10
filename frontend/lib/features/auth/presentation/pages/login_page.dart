/// Login Page - Premium Medical Design with Biometric Auth
/// CDC: Authentification JWT avec redirection par rôle + biométrie locale
library;

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

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  /// Whether the biometric button should be shown
  bool _showBiometricButton = false;

  /// Whether biometric is available on this device
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();

    // Load saved data + check biometric status
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    // Load last email
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_email');
    if (lastEmail != null) {
      _emailController.text = lastEmail;
    }

    // Check biometric availability and stored flag
    final biometricAvailableAsync = ref.read(isBiometricAvailableProvider);
    final biometricEnabled = ref.read(isBiometricEnabledProvider);

    biometricAvailableAsync.whenData((available) {
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _showBiometricButton = available && biometricEnabled;
        });

        // Auto-trigger biometric if enabled and available
        if (available && biometricEnabled) {
          _handleBiometricLogin();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// Login with email + password
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    authState.maybeWhen(
      data: (state) async {
        if (state.isAuthenticated) {
          // Save email for next time
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_email', _emailController.text.trim());

          // Role-based redirect
          if (state.user?.role == AppConstants.roleDoctor) {
            context.go(AppRoutes.doctorHome);
          } else {
            context.go(AppRoutes.patientHome);
          }
        }
      },
      orElse: () {},
    );

    authState.when(
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      data: (_) {},
    );
  }

  /// Login with biometric (fingerprint)
  ///
  /// Flow:
  /// 1. local_auth prompts for fingerprint
  /// 2. On success, stored JWT token is read from SecureStorage
  /// 3. Token is validated with server (/me endpoint)
  /// 4. If token expired, automatic refresh is attempted
  /// 5. If everything fails → fallback to password form
  Future<void> _handleBiometricLogin() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.loginWithBiometric();

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    authState.maybeWhen(
      data: (state) {
        if (state.isAuthenticated) {
          // Role-based redirect
          if (state.user?.role == AppConstants.roleDoctor) {
            context.go(AppRoutes.doctorHome);
          } else {
            context.go(AppRoutes.patientHome);
          }
        }
      },
      error: (error, _) {
        // Show error + keep password form visible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Mot de passe',
              textColor: Colors.white,
              onPressed: () {
                // Password form is already visible, just focus on it
              },
            ),
          ),
        );
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;

    // Also watch biometric state reactively
    final biometricEnabled = ref.watch(isBiometricEnabledProvider);
    final biometricAvailableAsync = ref.watch(isBiometricAvailableProvider);

    // Update biometric button visibility
    biometricAvailableAsync.whenData((available) {
      if (_biometricAvailable != available ||
          _showBiometricButton != (available && biometricEnabled)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _biometricAvailable = available;
              _showBiometricButton = available && biometricEnabled;
            });
          }
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                /// Logo + Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.medicalGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.shadowPrimary,
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bon retour !',
                        style: AppTheme.headlineLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous à votre compte MediConnect',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.neutralGray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Email
                      Text(
                        'Adresse email',
                        style: AppTheme.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                        decoration: const InputDecoration(
                          hintText: 'exemple@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Password
                      Text(
                        'Mot de passe',
                        style: AppTheme.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Se connecter'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Biometric button — only shown if enabled & available
                      if (_showBiometricButton) ...[
                        Center(
                          child: Column(
                            children: [
                              // Divider with text
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.neutralGray500
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'ou',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.neutralGray500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.neutralGray500
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Fingerprint button
                              GestureDetector(
                                onTap: isLoading ? null : _handleBiometricLogin,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primarySurface,
                                    border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 36,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Connexion par empreinte',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_biometricAvailable) ...[
                        // Biometric available but not enabled — show hint
                        Center(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Connectez-vous d\'abord, puis activez l\'empreinte dans les paramètres',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Connexion biométrique disponible',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.neutralGray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /// Register
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Créer un compte'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
