import 'package:flutter/material.dart';

import '../ui/animated_widgets.dart';
import '../ui/ui_kit.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradCtrl;
  late Animation<Alignment> _beginAlign;
  late Animation<Alignment> _endAlign;

  @override
  void initState() {
    super.initState();
    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _beginAlign = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topRight,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _gradCtrl, curve: Curves.easeInOut));
    _endAlign = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomLeft,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _gradCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // ─── Animated hero card ──────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 0),
                  child: AnimatedBuilder(
                    animation: _gradCtrl,
                    builder: (_, child) => Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          colors: const [
                            AppColors.softBlue,
                            AppColors.softPink,
                            AppColors.softPeach,
                          ],
                          begin: _beginAlign.value,
                          end: _endAlign.value,
                        ),
                      ),
                      child: child,
                    ),
                    child: Stack(
                      children: [
                        // Floating icon
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 160),
                          offset: const Offset(-18, 0),
                          child: Positioned(
                            top: 26,
                            right: 26,
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 34,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        // Content card
                        Positioned(
                          left: 22,
                          right: 22,
                          bottom: 22,
                          child: StaggeredFadeIn(
                            delay: const Duration(milliseconds: 80),
                            offset: const Offset(0, 18),
                            child: GlassCard(
                              radius: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OverDose',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Scan a product, understand the verdict, and track your decisions over time.',
                                    style: TextStyle(
                                      height: 1.5,
                                      color: AppColors.ink.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ─── Feature pills ───────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 160),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPoint(
                            icon: Icons.dashboard_customize_outlined,
                            title: 'Dashboard',
                            subtitle: 'Intelligent cumulative view',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPoint(
                            icon: Icons.center_focus_strong_outlined,
                            title: 'Scan',
                            subtitle: 'Quick or segmented analysis',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPoint(
                            icon: Icons.shield_outlined,
                            title: 'Protection',
                            subtitle: 'Personalized alerts',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── CTAs ────────────────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 240),
                  child: FilledButton(
                    onPressed: widget.onSignUp,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: OutlinedButton(
                    onPressed: widget.onSignIn,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPoint extends StatelessWidget {
  const _MiniPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.ink, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
