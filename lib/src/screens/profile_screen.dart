import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/animated_widgets.dart';
import '../ui/ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _newAllergyController = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'male';
  String _userType = '';
  int? _initializedUserId;
  final Set<int> _selectedAllergyIds = <int>{};
  bool _isEditing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _newAllergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final user = controller.currentUser;

    if (user != null && _initializedUserId != user.id) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _notesController.text = user.notes;
      _dateOfBirth = user.dateOfBirth;
      _gender = user.gender.isEmpty ? 'male' : user.gender;
      _userType = user.userType;
      _selectedAllergyIds
        ..clear()
        ..addAll(controller.selectedAllergyIds);
      _initializedUserId = user.id;
    }

    if (!_isEditing) {
      return _buildReadView(user, controller);
    }
    return _buildEditView(user, controller);
  }

  Widget _buildReadView(AppUser? user, AppController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
      children: [
        StaggeredFadeIn(
          child: HighlightBanner(
            title: 'My profile',
            subtitle: 'Personal information and health context.',
            icon: Icons.person_outline_rounded,
            colors: const [AppColors.softBlue, AppColors.softPink],
          ),
        ),
        const SizedBox(height: 16),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 60),
          child: _ProfileHeader(user: user),
        ),
        const SizedBox(height: 16),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 120),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  title: 'Information',
                  subtitle: 'Key account details',
                ),
                const SizedBox(height: 16),
                _buildInfoRow('First name', user?.firstName ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('Last name', user?.lastName ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('Email', user?.email ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Date of birth',
                  user?.dateOfBirth != null
                      ? DateFormat('dd/MM/yyyy').format(user!.dateOfBirth!)
                      : '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Gender', _formatGender(user?.gender ?? '')),
                const SizedBox(height: 8),
                _buildInfoRow('Health profile', user?.userTypeLabel ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 180),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  title: 'Allergies & sensitivities',
                  subtitle: 'Your personalized context',
                ),
                const SizedBox(height: 16),
                if (controller.selectedAllergyIds.isEmpty)
                  const Text(
                    'No allergies listed yet',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.allergies
                        .where(
                          (a) => controller.selectedAllergyIds.contains(a.id),
                        )
                        .map(
                          (a) => Chip(
                            label: Text(a.name),
                            backgroundColor: AppColors.softBlue.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                if (user != null && user.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Additional notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.notes,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 240),
          child: FilledButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Edit profile'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 280),
          child: OutlinedButton.icon(
            onPressed: controller.isBusy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                          'You will need to sign in again to access your data.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      await controller.logout();
                    }
                  },
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatGender(String gender) {
    return switch (gender) {
      'male' => 'Male',
      'female' => 'Female',
      'other' => 'Other',
      'prefer_not_to_say' => 'Not specified',
      _ => '-',
    };
  }

  Widget _buildEditView(AppUser? user, AppController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        HighlightBanner(
          title: 'Edit profile',
          subtitle: 'Edit your information, health profile, and allergies.',
          icon: Icons.edit_note_rounded,
          colors: const [AppColors.softPink, AppColors.softBlue],
        ),
        const SizedBox(height: 16),
        _ProfileHeader(user: user),
        const SizedBox(height: 16),
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  title: 'Personal information',
                  subtitle: 'Single edit flow with secure save.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First name'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'First name required'
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
                            ? 'Last name required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Email required'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _gender = value ?? 'male'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _userType.isEmpty ? null : _userType,
                  decoration: const InputDecoration(labelText: 'Health profile'),
                  items: const [
                    DropdownMenuItem(value: 'adult', child: Text('Adult')),
                    DropdownMenuItem(
                      value: 'pregnant',
                      child: Text('Pregnancy'),
                    ),
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                    DropdownMenuItem(
                      value: 'sensitive_skin',
                      child: Text('Sensitive skin'),
                    ),
                    DropdownMenuItem(value: 'athlete', child: Text('Athlete')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _userType = value ?? ''),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDateOfBirth,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    _dateOfBirth == null
                        ? 'Date of birth'
                        : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                    title: 'Allergies & notes',
                    subtitle:
                        'Select allergies and add any context that matters to you.',
                  ),
                  const SizedBox(height: 14),
                  if (controller.allergies.isEmpty)
                    const Chip(label: Text('No entries'))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.allergies.map((allergy) {
                    final selected = _selectedAllergyIds.contains(allergy.id);
                    return FilterChip(
                      label: Text(
                        allergy.name,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.ink,
                      checkmarkColor: Colors.white,
                      onSelected: controller.isBusy
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _selectedAllergyIds.add(allergy.id);
                              } else {
                                _selectedAllergyIds.remove(allergy.id);
                              }
                            }),
                    );
                    }).toList(),
                  ),
              const SizedBox(height: 16),
              Row(
                children: [
            Expanded(
                    child: TextField(
                      controller: _newAllergyController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Add an allergy',
                        hintText: 'e.g. peanut, soy, kiwi',
                      ),
                      onSubmitted: (_) => _addAllergy(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: controller.isBusy
                        ? null
                        : () => _addAllergy(context),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Additional notes',
                  hintText:
                      'e.g. sensitive to strong fragrances, vegetarian, etc.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isBusy
                    ? null
                    : () {
                        setState(() {
                          _isEditing = false;
                          _initializedUserId = null; // force reload from user
                        });
                      },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Cancel'),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: controller.isBusy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: controller.isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDateOfBirth() async {
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

  Future<void> _addAllergy(BuildContext context) async {
    final controller = context.read<AppController>();
    final rawName = _newAllergyController.text.trim();
    if (rawName.isEmpty) {
      return;
    }

    try {
      final allergy = await controller.createAllergy(rawName);
      if (!context.mounted) {
        return;
      }
      setState(() {
        _selectedAllergyIds.add(allergy.id);
        _newAllergyController.clear();
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Allergy added: ${allergy.name}'),
            backgroundColor: const Color(0xFF12372A),
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to add allergy: $error'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<AppController>();
    final current = controller.currentUser;
    if (current == null) {
      return;
    }

    final updatedUser = current.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      userType: _userType,
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      notes: _notesController.text.trim(),
    );

    await controller.saveProfilePreferences(
      updatedUser: updatedUser,
      allergyIds: _selectedAllergyIds.toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile and allergies saved.'),
        backgroundColor: Color(0xFF12372A),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser? user;

  String get _initials {
    final first = user?.firstName.trim() ?? '';
    final last = user?.lastName.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return '?';
    final f = first.isEmpty ? '' : first[0].toUpperCase();
    final l = last.isEmpty ? '' : last[0].toUpperCase();
    return '$f$l';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.softBlue, AppColors.softPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Profile not connected',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Sign in to sync your data',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user?.userTypeLabel ?? 'Not set',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
