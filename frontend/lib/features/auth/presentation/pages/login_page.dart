/// Login Page - Premium Medical Design
/// CDC: Authentification JWT avec redirection par rôle
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

                // ── Logo & Welcome ──────────────────
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

                // ── Form ────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
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

                      // Password field
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
                      const SizedBox(height: 12),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Navigate to forgot password
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login button
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
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Se connecter',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Biometric login
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
                                onPressed: () {
                                  // TODO: Biometric auth
                                },
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

                // ── Divider ─────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppTheme.neutralGray300),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Nouveau sur MediConnect ?',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutralGray500,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppTheme.neutralGray300),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Register button ─────────────────
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
