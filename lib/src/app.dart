import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'ui/ui_kit.dart';

class OverDoseApp extends StatelessWidget {
  const OverDoseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController()..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OverDose',
        themeMode: ThemeMode.light,
        theme: buildAppTheme(Brightness.light),
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    final Widget page;

    if (controller.isBootstrapping) {
      page = const _BootScreen(key: ValueKey('boot'));
    } else if (controller.isAuthenticated) {
      if (controller.needsOnboarding) {
        page = const OnboardingScreen(key: ValueKey('onboarding'));
      } else {
        page = const AppShell(key: ValueKey('shell'));
      }
    } else {
      page = _WelcomeAuthFlow(key: const ValueKey('auth'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: page,
    );
  }
}

class _WelcomeAuthFlow extends StatefulWidget {
  const _WelcomeAuthFlow({super.key});

  @override
  State<_WelcomeAuthFlow> createState() => _WelcomeAuthFlowState();
}

class _WelcomeAuthFlowState extends State<_WelcomeAuthFlow> {
  bool _showAuth = false;
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    if (_showAuth) {
      return LoginScreen(
        key: ValueKey(_showRegister),
        initialRegister: _showRegister,
        onBack: () => setState(() => _showAuth = false),
      );
    }
    return WelcomeScreen(
      onSignIn: () => setState(() {
        _showRegister = false;
        _showAuth = true;
      }),
      onSignUp: () => setState(() {
        _showRegister = true;
        _showAuth = true;
      }),
    );
  }
}

class _BootScreen extends StatefulWidget {
  const _BootScreen({super.key});

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.6, end: 1.0));
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.center_focus_strong_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: const Text(
                    'OverDose',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your intelligent health assistant',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.ink.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
