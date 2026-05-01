import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../listings/presentation/screens/biz_screen.dart';
import '../listings/presentation/screens/home_screen.dart';
import '../listings/presentation/screens/jobs_screen.dart';
import '../listings/presentation/widgets/plus_sheet.dart';
import '../profile/presentation/profile_screen.dart';
import 'bottom_nav.dart';

/// Top-level scaffold that hosts the four tabs and manages the floating
/// glassy bottom-nav. Mirrors the React `App` from `Job Alert App - Main.html`.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 0;
  bool _navHidden = false;
  double _lastScroll = 0;

  void _onScroll(double y) {
    if (y > _lastScroll + 12) {
      if (!_navHidden) setState(() => _navHidden = true);
    } else if (y < _lastScroll - 12) {
      if (_navHidden) setState(() => _navHidden = false);
    }
    _lastScroll = y;
  }

  void _setTab(int i) {
    setState(() {
      _tab = i;
      _navHidden = false;
    });
    _lastScroll = 0;
  }

  void _openPlusSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      useSafeArea: true,
      builder: (_) => const PlusSheet(),
    );
  }

  /// Phone-form-factor cap. The design is mobile-only — on tablets and
  /// foldables we constrain the shell to a phone-shaped column instead of
  /// stretching the layout horizontally, which would otherwise distort
  /// every floating card and pill in the design.
  static const double _maxShellWidth = 520;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(onSwitchTab: _setTab, onScroll: _onScroll),
      JobsScreen(onScroll: _onScroll),
      BizScreen(onScroll: _onScroll),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0E4),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxShellWidth),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  IndexedStack(index: _tab, children: tabs),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8 + MediaQuery.of(context).padding.bottom,
                    child: AppBottomNav(
                      activeIndex: _tab,
                      hidden: _navHidden && _tab != 0,
                      onTap: _setTab,
                      onPlus: _openPlusSheet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
