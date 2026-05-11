import 'package:flutter/material.dart';
import 'ui_kit.dart';

// ─── StaggeredFadeIn ───────────────────────────────────────────────────────
/// Wraps [child] with a fade+slide-up animation that starts after [delay].
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offset = const Offset(0, 28),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (_, child) =>
            Transform.translate(offset: _slide.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── AnimatedCounter ──────────────────────────────────────────────────────
/// Animates an integer value change with a rolling count-up effect.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (_, v, __) => Text('$v', style: style),
    );
  }
}

// ─── ShimmerCard ──────────────────────────────────────────────────────────
/// Pulsing placeholder skeleton while content is loading.
class ShimmerCard extends StatefulWidget {
  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 24,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.softBlue.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ─── VerdictBadge ─────────────────────────────────────────────────────────
/// Colored badge representing a cumulative verdict recommendation.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.recommendation});

  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (recommendation.toLowerCase()) {
      'eliminate' => (AppColors.danger, 'Avoid', Icons.block_outlined),
      'reduce' => (AppColors.warning, 'Reduce', Icons.trending_down_rounded),
      'keep' => (AppColors.success, 'Safe', Icons.check_circle_outline),
      _ => (AppColors.muted, 'Unknown', Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OrganChip ────────────────────────────────────────────────────────────
/// Visual chip for organs under pressure.
class OrganChip extends StatelessWidget {
  const OrganChip({super.key, required this.organ});

  final String organ;

  static IconData _iconFor(String organ) {
    final lower = organ.toLowerCase();
    if (lower.contains('liver') || lower.contains('foie')) return Icons.opacity;
    if (lower.contains('kidney') || lower.contains('rein'))
      return Icons.water_drop_outlined;
    if (lower.contains('skin') || lower.contains('peau'))
      return Icons.face_outlined;
    if (lower.contains('lung') || lower.contains('poumon')) return Icons.air;
    if (lower.contains('heart') ||
        lower.contains('coeur') ||
        lower.contains('cœur'))
      return Icons.favorite_outline;
    if (lower.contains('brain') || lower.contains('cerveau'))
      return Icons.psychology_outlined;
    return Icons.medical_services_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7D6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.softPeach.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(organ), size: 13, color: AppColors.warning),
          const SizedBox(width: 5),
          Text(
            organ,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PulsingDot ───────────────────────────────────────────────────────────
/// Animated pulsing status indicator.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.color = AppColors.danger, this.size = 10});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.45),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HealthScoreRing ──────────────────────────────────────────────────────
/// Animated circular health score indicator.
class HealthScoreRing extends StatelessWidget {
  const HealthScoreRing({
    super.key,
    required this.score,
    this.size = 80,
    this.strokeWidth = 7,
    this.duration = const Duration(milliseconds: 900),
  });

  final int score;
  final double size;
  final double strokeWidth;
  final Duration duration;

  Color get _color {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                color: AppColors.softBlue,
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                color: _color,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.25,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: size * 0.14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
