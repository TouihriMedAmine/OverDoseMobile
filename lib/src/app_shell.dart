import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'ui/ui_kit.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    // Guard: only refreshSession if still authenticated to avoid race condition
    // when a logout happens right before the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<AppController>();
      if (ctrl.isAuthenticated) {
        ctrl.refreshSession(allowLogout: true, silent: true);
      }
    });
  }

  void _onTabSelected(int value) {
    if (value == _index) return;
    setState(() {
      _previousIndex = _index;
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const ScanScreen(),
      const ProductsScreen(),
      const ProfileScreen(),
    ];

    return _AppShellScope(
      goToTab: _onTabSelected,
      child: Scaffold(
        extendBody: true,
        // No global AppBar — each screen owns its header for immersive design
        body: Container(
          decoration: buildPageBackground(),
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.06),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 1.2,
                    ),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    height: 70,
                    selectedIndex: _index,
                    onDestinationSelected: _onTabSelected,
                    animationDuration: const Duration(milliseconds: 300),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.center_focus_strong_outlined),
                        selectedIcon: Icon(Icons.center_focus_strong),
                        label: 'Scan',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: 'Products',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShellScope extends InheritedWidget {
  const _AppShellScope({required this.goToTab, required super.child});

  final ValueChanged<int> goToTab;

  static _AppShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppShellScope>();
    assert(scope != null, 'No AppShell scope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(_AppShellScope oldWidget) => false;
}

extension AppShellNavigationX on BuildContext {
  void switchHomeTab(int index) {
    _AppShellScope.of(this).goToTab(index);
  }
}
