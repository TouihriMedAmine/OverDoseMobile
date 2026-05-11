import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../ui/ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRegister = false, this.onBack});

  final bool initialRegister;
  final VoidCallback? onBack;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'male';
  late bool _showRegister = widget.initialRegister;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: controller.isBusy
                              ? null
                              : () => setState(
                                  () => _showRegister = !_showRegister,
                                ),
                          child: Text(_showRegister ? 'Sign in' : 'Sign up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HighlightBanner(
                      title: _showRegister
                          ? 'Create your personal space'
                          : 'Welcome back to OverDose',
                      subtitle: _showRegister
                          ? 'One account to scan, save products, and track your health trends.'
                          : 'Sign in with your email to access your dashboard, products, and recommendations.',
                      icon: _showRegister
                          ? Icons.person_add_alt_1_rounded
                          : Icons.lock_open_rounded,
                      colors: const [AppColors.softPeach, AppColors.softPink],
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: controller.errorMessage!),
                    ],
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _showRegister
                          ? _buildRegisterForm(context)
                          : _buildLoginForm(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final controller = context.watch<AppController>();

    return GlassCard(
      key: const ValueKey('login'),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'Sign in',
              subtitle: 'Use your email as your account identifier.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Email is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPasswordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Password is required'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.isBusy ? null : _submitLogin,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: controller.isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final controller = context.watch<AppController>();

    return GlassCard(
      key: const ValueKey('register'),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'Create account',
              subtitle: 'Simple form with only essential fields.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'First name is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Last name is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Email is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 6)
                  ? 'Minimum 6 characters'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value ?? 'other'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickBirthDate,
              icon: const Icon(Icons.cake_outlined),
              label: Text(
                _dateOfBirth == null
                    ? 'Date of birth'
                    : _dateOfBirth!.toIso8601String().split('T').first,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.isBusy ? null : _submitRegister,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: controller.isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    try {
      await context.read<AppController>().login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
    } catch (_) {}
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    try {
      await context.read<AppController>().register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
      );
    } catch (_) {}
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7F2D21)),
            ),
          ),
        ],
      ),
    );
  }
}
