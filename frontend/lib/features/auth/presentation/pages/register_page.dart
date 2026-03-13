/// Register Page - Multi-step registration with role selection
/// CDC: Inscription avec choix de rôle (Patient / Médecin)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specialityController = TextEditingController();
  final _licenseController = TextEditingController();

  String _selectedRole = AppConstants.rolePatient;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialityController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          role: _selectedRole,
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text.trim()
              : null,
          speciality: _selectedRole == AppConstants.roleDoctor
              ? _specialityController.text.trim()
              : null,
          licenseNumber: _selectedRole == AppConstants.roleDoctor
              ? _licenseController.text.trim()
              : null,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Step indicator ──────────────────
                _buildStepIndicator(),
                const SizedBox(height: 32),

                // ── Step content ────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildRoleSelection()
                      : _currentStep == 1
                          ? _buildPersonalInfo()
                          : _buildSecurityInfo(),
                ),

                const SizedBox(height: 32),

                // ── Navigation Buttons ──────────────
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _currentStep--);
                          },
                          child: const Text('Précédent'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_currentStep < 2) {
                                  setState(() => _currentStep++);
                                } else {
                                  _handleRegister();
                                }
                              },
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
                                _currentStep < 2
                                    ? 'Suivant'
                                    : 'Créer mon compte',
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Login link ──────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.neutralGray500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  // ── Step Indicator ──────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.neutralGray200,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: AppTheme.labelLarge.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.neutralGray500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['Rôle', 'Infos', 'Sécurité'][index],
                      style: AppTheme.labelSmall.copyWith(
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.neutralGray400,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < 2)
                Expanded(
                  child: Divider(
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : AppTheme.neutralGray300,
                    thickness: 2,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Step 1: Role Selection ──────────────────────────────

  Widget _buildRoleSelection() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vous êtes...',
          style: AppTheme.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez votre profil pour une expérience adaptée',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.neutralGray500,
          ),
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          role: AppConstants.rolePatient,
          icon: Icons.person_rounded,
          title: 'Patient',
          description:
              'Prenez rendez-vous, consultez votre médecin et gérez votre dossier médical.',
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: AppConstants.roleDoctor,
          icon: Icons.medical_services_rounded,
          title: 'Médecin',
          description:
              'Gérez vos patients, votre planning et vos consultations en ligne.',
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(height: 16),
      _buildRoleCard(
        role: AppConstants.roleSecretary,
        icon: Icons.badge_rounded,
        title: 'Secrétaire',
        description: 'Gérez les rendez-vous, le planning et l’accueil des patients.',
        color: const Color.fromARGB(255, 0, 40, 150),
      ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.neutralGray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.shadowMd : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppTheme.neutralGray300,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Personal Info ───────────────────────────────

  Widget _buildPersonalInfo() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: AppTheme.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('Nom complet'),
        TextFormField(
          controller: _nameController,
          validator: Validators.name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Dr. Jean Dupont',
            prefixIcon: Icon(Icons.person_outlined),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Adresse email'),
        TextFormField(
          controller: _emailController,
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'exemple@email.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Téléphone'),
        TextFormField(
          controller: _phoneController,
          validator: Validators.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: '06 12 34 56 78',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),

        // Doctor-specific fields
        if (_selectedRole == AppConstants.roleDoctor) ...[
          const SizedBox(height: 16),
          _buildLabel('Spécialité'),
          TextFormField(
            controller: _specialityController,
            validator: (v) => Validators.required(v, 'La spécialité'),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Médecine générale',
              prefixIcon: Icon(Icons.medical_information_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Numéro d\'ordre'),
          TextFormField(
            controller: _licenseController,
            validator: Validators.licenseNumber,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'XXXXX',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
        ],
        if (_selectedRole == AppConstants.roleSecretary) ...[
        const SizedBox(height: 16),
        _buildLabel('Département'),
        TextFormField(
          controller: _specialityController, // ou créer _departmentController
          validator: (v) => Validators.required(v, 'Le département'),
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Accueil / Administration',
            prefixIcon: Icon(Icons.apartment_outlined),
          ),
        ),
      ],
      ],
    );
  }

  // ── Step 3: Security Info ───────────────────────────────

  Widget _buildSecurityInfo() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sécurité du compte',
          style: AppTheme.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez un mot de passe fort pour protéger vos données médicales.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.neutralGray500,
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('Mot de passe'),
        TextFormField(
          controller: _passwordController,
          validator: Validators.password,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Password requirements
        _buildPasswordRequirement(
          'Au moins 8 caractères',
          _passwordController.text.length >= 8,
        ),
        _buildPasswordRequirement(
          'Une lettre majuscule',
          RegExp(r'[A-Z]').hasMatch(_passwordController.text),
        ),
        _buildPasswordRequirement(
          'Un chiffre',
          RegExp(r'[0-9]').hasMatch(_passwordController.text),
        ),
        _buildPasswordRequirement(
          'Un caractère spécial',
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text),
        ),

        const SizedBox(height: 16),
        _buildLabel('Confirmer le mot de passe'),
        TextFormField(
          controller: _confirmPasswordController,
          validator: (v) =>
              Validators.confirmPassword(v, _passwordController.text),
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Terms checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v!),
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'J\'accepte les ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray600,
                  ),
                  children: [
                    TextSpan(
                      text: 'conditions d\'utilisation',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' et la '),
                    TextSpan(
                      text: 'politique de confidentialité RGPD',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.labelLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppTheme.successColor : AppTheme.neutralGray400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: isMet ? AppTheme.successColor : AppTheme.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }
}
