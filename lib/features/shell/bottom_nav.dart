import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Detached, glassy 62-px-tall pill nav with the floating black plus button
/// floating 14 px above the pill — exact match for `.bottom-nav` in the
/// design.
///
/// The plus button is rendered as a Stack overlay that sits OUTSIDE the
/// nav's `ClipRRect`, otherwise the upper half of the floating button gets
/// clipped by the rounded-rect mask used to render the glass blur.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
    required this.onPlus,
    this.hidden = false,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;
  final bool hidden;

  // Layout constants — must match the design CSS.
  // The plus button is centered in the 62-px row then shifted up 20 px,
  // which leaves it overhanging the pill's top edge by exactly 14 px:
  //     centered top = (62-50)/2 = 6     →   shifted top = -14
  static const double _navHeight = 62;
  static const double _plusSize = 50;
  static const double _plusOverhang = 14;

  /// Total height the nav reserves, including the plus button overhang.
  /// MainShell uses this to size the bottom inset on scrollables.
  static const double overhangHeight = _navHeight + _plusOverhang;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: hidden ? const Offset(0, 1.6) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hidden ? 0 : 1,
        child: SizedBox(
          height: overhangHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Glass nav pill — clipped + blurred.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: _navHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xD9FFFFFF),
                        border: Border.all(color: const Color(0x73D2D2D2)),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 8)),
                          BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          _NavItem(icon: Icons.home_outlined, label: 'Home', active: activeIndex == 0, onTap: () => onTap(0)),
                          _NavItem(icon: Icons.work_outline, label: 'Jobs', active: activeIndex == 1, onTap: () => onTap(1)),
                          // Reserve horizontal space for the floating plus —
                          // matches `.nav-plus { width: 50px }` slot in CSS.
                          const SizedBox(width: _plusSize),
                          _NavItem(icon: Icons.bar_chart_outlined, label: 'Biz', active: activeIndex == 2, onTap: () => onTap(2)),
                          _NavItem(icon: Icons.person_outline, label: 'Profile', active: activeIndex == 3, onTap: () => onTap(3)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Floating plus — rendered above the clip so it overflows
              // the nav's rounded silhouette by `_plusLift` pixels.
              Positioned(
                top: 0,
                child: SizedBox(
                  width: _plusSize + 12,
                  height: _plusSize,
                  child: Center(child: _PlusButton(onTap: onPlus, size: _plusSize)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : const Color(0xFFC0C0C0);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.captionMuted.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: active ? 1 : 0,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusButton extends StatefulWidget {
  const _PlusButton({required this.onTap, required this.size});
  final VoidCallback onTap;
  final double size;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  /// Single 3-second cycle that pulses 0 → 1 → 0 (via `sin(π·t)`),
  /// matching the design's `plusPulse` keyframes.
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  bool _pressed = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.93 : 1.0,
        child: AnimatedBuilder(
          animation: _ctl,
          builder: (_, __) {
            // sin(π·t) oscillates 0 → 1 → 0 over one cycle.
            final pulse = math.sin(math.pi * _ctl.value);
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: AppColors.ink900,
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x52000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1E1E1E).withOpacity(0.18 * pulse),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            );
          },
        ),
      ),
    );
  }
}
