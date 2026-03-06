/// Login Page - Premium Medical Design
/// CDC: Authentification JWT avec redirection par rôle
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

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

  /// 🔹 Biométrie
  final LocalAuthentication _auth = LocalAuthentication();

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// 🔹 Login normal
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    authState.when(
      data: (state) {
        if (state.isAuthenticated) {
          if (state.user?.role == AppConstants.roleDoctor) {
            context.go(AppRoutes.doctorHome);
          } else {
            context.go(AppRoutes.patientHome);
          }
        }
      },
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
    );
  }

  /// 🔹 Authentification biométrique
  Future<void> _authenticateWithBiometrics() async {
    try {

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("La biométrie n'est pas disponible sur cet appareil"),
          ),
        );
        return;
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Utilisez votre empreinte pour vous connecter',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {

        final authState = ref.read(authNotifierProvider);

        authState.when(
          data: (state) {
            if (state.isAuthenticated) {
              if (state.user?.role == AppConstants.roleDoctor) {
                context.go(AppRoutes.doctorHome);
              } else {
                context.go(AppRoutes.patientHome);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Veuillez vous connecter une première fois pour activer l'empreinte",
                  ),
                ),
              );
            }
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      }

    } on PlatformException catch (e) {
      debugPrint("Erreur biométrie: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;

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

                /// Logo
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

                /// Formulaire
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
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Se connecter'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Biométrie
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primarySurface,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.fingerprint_rounded,
                                  size: 32,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: _authenticateWithBiometrics,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connexion biométrique',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.neutralGray500,
                              ),
                            ),
                          ],
                        ),
                      ),
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