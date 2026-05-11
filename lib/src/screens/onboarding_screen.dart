import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/animated_widgets.dart';
import '../ui/ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  int _step = 0;
  static const int _totalSteps = 5;

  // Step 1 — objective
  String _objective = '';

  // Step 2 — user type
  String _userType = '';

  // Step 3 — allergies
  final Set<int> _selectedAllergies = {};

  // Step 4 — notifications
  bool _notifyHighRisk = true;
  bool _notifyControversial = false;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1 / _totalSteps).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _animateProgress(int toStep) {
    _progressAnim =
        Tween<double>(
          begin: _step / _totalSteps,
          end: toStep / _totalSteps,
        ).animate(
          CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
        );
    _progressCtrl.forward(from: 0);
  }

  void _goNext() {
    if (_step < _totalSteps - 1) {
      final next = _step + 1;
      _animateProgress(next);
      setState(() => _step = next);
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step > 0) {
      final prev = _step - 1;
      _animateProgress(prev);
      setState(() => _step = prev);
      _pageCtrl.animateToPage(
        prev,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _canProceed {
    return switch (_step) {
      0 => _objective.isNotEmpty,
      1 => _userType.isNotEmpty,
      2 => true, // allergies optional
      3 => true, // notifications optional
      4 => true, // confirmation
      _ => false,
    };
  }

  Future<void> _submit() async {
    final ctrl = context.read<AppController>();
    // Map objective to userType if user skipped step 2
    final finalType = _userType.isEmpty ? 'adult' : _userType;
    try {
      await ctrl.completeOnboarding(
        userType: finalType,
        allergyIds: _selectedAllergies.toList(),
        notifyHighRisk: _notifyHighRisk,
        notifyControversial: _notifyControversial,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save your profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();

    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Step ${_step + 1} of $_totalSteps',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedBuilder(
                              animation: _progressAnim,
                              builder: (_, __) => LinearProgressIndicator(
                                value: _progressAnim.value,
                                backgroundColor: AppColors.softBlue.withValues(
                                  alpha: 0.5,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.ink,
                                ),
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: ctrl.isBusy ? null : ctrl.skipOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              // ─── Pages ───────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepObjective(
                      selected: _objective,
                      onSelect: (v) => setState(() => _objective = v),
                    ),
                    _StepUserType(
                      selected: _userType,
                      onSelect: (v) => setState(() => _userType = v),
                    ),
                    _StepAllergies(
                      allergies: ctrl.allergies,
                      selected: _selectedAllergies,
                      onToggle: (id) => setState(() {
                        if (_selectedAllergies.contains(id)) {
                          _selectedAllergies.remove(id);
                        } else {
                          _selectedAllergies.add(id);
                        }
                      }),
                      onAdd: (name) async {
                        try {
                          final a = await ctrl.createAllergy(name);
                          setState(() => _selectedAllergies.add(a.id));
                        } catch (_) {}
                      },
                    ),
                    _StepNotifications(
                      notifyHighRisk: _notifyHighRisk,
                      notifyControversial: _notifyControversial,
                      onHighRisk: (v) => setState(() => _notifyHighRisk = v),
                      onControversial: (v) =>
                          setState(() => _notifyControversial = v),
                    ),
                    _StepConfirmation(
                      objective: _objective,
                      userType: _userType,
                      allergyCount: _selectedAllergies.length,
                    ),
                  ],
                ),
              ),
              // ─── CTA Button ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: FilledButton(
                  onPressed: (!_canProceed || ctrl.isBusy) ? null : _goNext,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: ctrl.isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step < _totalSteps - 1 ? 'Continue' : 'Start',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 1 : Objective ───────────────────────────────────────────────────────
class _StepObjective extends StatelessWidget {
  const _StepObjective({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  static const _options = [
    (
      'health',
      'Overall health',
      Icons.favorite_outline,
      'Monitor day-to-day consumption',
    ),
    (
      'sport',
      'Sport & performance',
      Icons.fitness_center_outlined,
      'Optimize performance nutrition',
    ),
    (
      'skin',
      'Skin & cosmetics',
      Icons.face_outlined,
      'Choose safe products for my skin',
    ),
    (
      'nutrition',
      'Nutrition & weight',
      Icons.restaurant_outlined,
      'Control nutritional intake',
    ),
    (
      'family',
      'Family & kids',
      Icons.family_restroom_outlined,
      'Protect the whole family',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      question: 'What is your primary goal?',
      hint: 'Your assistant will adapt its recommendations accordingly.',
      child: Column(
        children: _options.map((opt) {
          final isSelected = selected == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceCard(
              icon: opt.$3,
              title: opt.$2,
              subtitle: opt.$4,
              selected: isSelected,
              onTap: () => onSelect(opt.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Step 2 : User type ───────────────────────────────────────────────────────
class _StepUserType extends StatelessWidget {
  const _StepUserType({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  static const _options = [
    ('adult', 'Adult', Icons.person_outline, 'General adult use'),
    (
      'pregnant',
      'Pregnancy',
      Icons.pregnant_woman_outlined,
      'Pregnancy and postpartum support',
    ),
    (
      'child',
      'Child',
      Icons.child_care_outlined,
      'Products suitable for children',
    ),
    (
      'sensitive_skin',
      'Sensitive skin',
      Icons.spa_outlined,
      'Avoid skin irritants',
    ),
    (
      'athlete',
      'Athlete',
      Icons.directions_run_outlined,
      'Performance and recovery',
    ),
    ('other', 'Other', Icons.more_horiz_outlined, 'Custom profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      question: 'Describe your health profile',
      hint: 'Helps tailor risk analysis to your situation.',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
        children: _options.map((opt) {
          final isSelected = selected == opt.$1;
          return _GridChoiceCard(
            icon: opt.$3,
            title: opt.$2,
            subtitle: opt.$4,
            selected: isSelected,
            onTap: () => onSelect(opt.$1),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Step 3 : Allergies ───────────────────────────────────────────────────────
class _StepAllergies extends StatefulWidget {
  const _StepAllergies({
    required this.allergies,
    required this.selected,
    required this.onToggle,
    required this.onAdd,
  });
  final List<AllergyItem> allergies;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final Future<void> Function(String) onAdd;

  @override
  State<_StepAllergies> createState() => _StepAllergiesState();
}

class _StepAllergiesState extends State<_StepAllergies> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      question: 'Do you have allergies or sensitivities?',
      hint: 'Optional - you can update this later in your profile.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.allergies.map((a) {
              final sel = widget.selected.contains(a.id);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                child: FilterChip(
                  label: Text(
                    a.name,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: sel,
                  selectedColor: AppColors.ink,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => widget.onToggle(a.id),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Other allergy or sensitivity',
                    hintText: 'Example: kiwi, latex...',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) async {
                    if (v.trim().isEmpty) return;
                    await widget.onAdd(v.trim());
                    _ctrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () async {
                  final v = _ctrl.text.trim();
                  if (v.isEmpty) return;
                  await widget.onAdd(v);
                  _ctrl.clear();
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 4 : Notifications ───────────────────────────────────────────────────
class _StepNotifications extends StatelessWidget {
  const _StepNotifications({
    required this.notifyHighRisk,
    required this.notifyControversial,
    required this.onHighRisk,
    required this.onControversial,
  });
  final bool notifyHighRisk;
  final bool notifyControversial;
  final ValueChanged<bool> onHighRisk;
  final ValueChanged<bool> onControversial;

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      question: 'Do you want safety alerts?',
      hint: 'Customize your notification preferences.',
      child: Column(
        children: [
          _ToggleOption(
            title: 'High-risk products',
            subtitle:
                'Alert when a scanned product contains dangerous ingredients.',
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            value: notifyHighRisk,
            onChanged: onHighRisk,
          ),
          const SizedBox(height: 12),
          _ToggleOption(
            title: 'Controversial ingredients',
            subtitle:
                'Notify when debated additives and preservatives are detected.',
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
            value: notifyControversial,
            onChanged: onControversial,
          ),
        ],
      ),
    );
  }
}

// ─── Step 5 : Confirmation ────────────────────────────────────────────────────
class _StepConfirmation extends StatelessWidget {
  const _StepConfirmation({
    required this.objective,
    required this.userType,
    required this.allergyCount,
  });
  final String objective;
  final String userType;
  final int allergyCount;

  static const _objLabels = {
    'health': 'Overall health',
    'sport': 'Sport & Performance',
    'skin': 'Skin & Cosmetics',
    'nutrition': 'Nutrition & Weight',
    'family': 'Family & Kids',
  };

  static const _typeLabels = {
    'adult': 'Adult',
    'pregnant': 'Pregnancy',
    'child': 'Child',
    'sensitive_skin': 'Sensitive skin',
    'athlete': 'Athlete',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      question: 'Your profile is ready ✓',
      hint: 'Here is what we captured. You can update everything later.',
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.my_library_books_outlined,
            label: 'Goal',
            value: _objLabels[objective] ?? 'Overall health',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.person_outline,
            label: 'Health profile',
            value: _typeLabels[userType] ?? 'Adult',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.local_pharmacy_outlined,
            label: 'Sensitivities',
            value: allergyCount == 0
                ? 'None selected'
                : '$allergyCount selected',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.softBlue, AppColors.softPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.ink),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your assistant adapts as you scan more products to refine recommendations.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.4,
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

// ─── Shared sub-widgets ───────────────────────────────────────────────────────
class _StepWrapper extends StatelessWidget {
  const _StepWrapper({
    required this.question,
    required this.hint,
    required this.child,
  });
  final String question;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFadeIn(
            child: Text(
              question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 60),
            child: Text(
              hint,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 120),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.ink
                : AppColors.ink.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.softBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GridChoiceCard extends StatelessWidget {
  const _GridChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.ink
                : AppColors.ink.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.ink,
              size: 26,
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withValues(alpha: 0.65)
                    : AppColors.muted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.ink,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
