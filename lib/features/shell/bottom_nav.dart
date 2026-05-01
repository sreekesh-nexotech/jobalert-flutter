import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Detached, glassy 62-px-tall pill nav with the floating black plus button
/// in the middle — exact match for `.bottom-nav` in the design.
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: hidden ? const Offset(0, 1.3) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hidden ? 0 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 62,
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
                  _PlusButton(onTap: onPlus),
                  _NavItem(icon: Icons.bar_chart_outlined, label: 'Biz', active: activeIndex == 2, onTap: () => onTap(2)),
                  _NavItem(icon: Icons.person_outline, label: 'Profile', active: activeIndex == 3, onTap: () => onTap(3)),
                ],
              ),
            ),
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
  const _PlusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) {
          final glow = (Curves.easeInOut.transform(_ctl.value)) * 0.18;
          return Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.ink900,
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(color: Color(0x52000000), blurRadius: 20, offset: Offset(0, 6)),
                  BoxShadow(color: Color.fromRGBO(30, 30, 30, glow), blurRadius: 28, spreadRadius: 8),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          );
        },
      ),
    );
  }
}
