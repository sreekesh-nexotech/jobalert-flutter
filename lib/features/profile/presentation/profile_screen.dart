import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../listings/presentation/listings_controller.dart';

const _cities = <String>[
  'Bengaluru', 'Chennai', 'Mumbai', 'Delhi', 'Hyderabad', 'Kochi', 'Pune',
  'Ahmedabad', 'Kolkata', 'Jaipur', 'Lucknow', 'Coimbatore', 'Surat', 'Indore',
];

const _categories = ['Design', 'Tech', 'Marketing', 'Media', 'Finance', 'Healthcare', 'HR', 'Sales'];

/// Profile tab — gradient hero with avatar/stats, points card, preferences,
/// premium teaser, and the menu sections.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _city = 'Kochi';
  final Set<String> _prefs = {'Design', 'Marketing'};

  void _togglePref(String c) {
    setState(() {
      if (_prefs.contains(c)) {
        _prefs.remove(c);
      } else {
        _prefs.add(c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final stats = ref.watch(profileStatsProvider);

    final pts = stats.maybeWhen(data: (m) => (m['points'] as int?) ?? 0, orElse: () => 0);
    final nextLvlAt = stats.maybeWhen(data: (m) => m['next_level_at'] as int?, orElse: () => null);
    final levelLabel = stats.maybeWhen(data: (m) => (m['points_level'] as String?) ?? 'Newcomer', orElse: () => 'Newcomer');
    final nextLevel = stats.maybeWhen(data: (m) => m['next_level'] as String?, orElse: () => null);
    final progress = nextLvlAt == null
        ? 1.0
        : (pts / nextLvlAt).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    final posts = stats.maybeWhen(data: (m) => (m['posts'] as int?) ?? 0, orElse: () => 0);
    final saved = stats.maybeWhen(data: (m) => (m['saved'] as int?) ?? 0, orElse: () => 0);
    final upvotes = stats.maybeWhen(data: (m) => (m['upvotes_given'] as int?) ?? 0, orElse: () => 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.peachBg, AppColors.beigeBg, AppColors.sageBg],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brand, AppColors.sage],
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.brand.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initials ?? '?',
                        style: AppText.h1.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02 * 28,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.ink900,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'You',
                  style: AppText.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02 * 18,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _city,
                        items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _city = v ?? 'Kochi'),
                        style: AppText.body.copyWith(fontSize: 13, color: const Color(0xFF888888)),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFFAAAAAA)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    children: [
                      _StatItem(value: posts, label: 'Posts'),
                      _divider(),
                      _StatItem(value: saved, label: 'Saved'),
                      _divider(),
                      _StatItem(value: upvotes, label: 'Upvotes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _PointsCard(
                  points: pts,
                  level: levelLabel,
                  nextLevel: nextLevel,
                  pct: pct,
                  remaining: nextLvlAt == null ? 0 : (nextLvlAt - pts).clamp(0, 99999),
                ),
                const SizedBox(height: 12),
                _PreferencesCard(prefs: _prefs, onToggle: _togglePref),
                const SizedBox(height: 12),
                const _PremiumCard(),
                const SizedBox(height: 12),
                _MenuSection(items: const [
                  _MenuItem(icon: '🔒', label: 'Privacy Policy', bg: AppColors.ink100),
                  _MenuItem(icon: '❓', label: 'Help & Support', bg: AppColors.ink100),
                  _MenuItem(icon: '⭐', label: 'Rate the App', bg: AppColors.peachBg),
                  _MenuItem(icon: '📋', label: 'Terms of Service', bg: AppColors.ink100),
                ]),
                const SizedBox(height: 12),
                _MenuSection(items: [
                  const _MenuItem(icon: '🗑️', label: 'Delete Account', bg: AppColors.dangerBg, danger: true),
                  _MenuItem(
                    icon: '🚪',
                    label: 'Logout',
                    bg: AppColors.dangerBg,
                    danger: true,
                    onTap: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: AppColors.ink50);
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              '$value',
              style: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
                letterSpacing: -0.02 * 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppText.captionMuted.copyWith(fontSize: 10, color: AppColors.ink400)),
          ],
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({
    required this.points,
    required this.level,
    required this.nextLevel,
    required this.pct,
    required this.remaining,
  });
  final int points;
  final String level;
  final String? nextLevel;
  final int pct;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.peachBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ YOUR POINTS',
                      style: AppText.captionMuted.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                        letterSpacing: 0.06 * 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$points',
                      style: AppText.h1.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.03 * 22,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      nextLevel == null
                          ? '$level · Top tier'
                          : '$level · $pct% to $nextLevel',
                      style: AppText.captionMuted.copyWith(fontSize: 11, color: const Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              const Text('🏅', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: AppColors.brand.withOpacity(0.15),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brand, AppColors.brandLight],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextLevel == null
                ? 'You\'re at the top level — keep going!'
                : '$remaining more points to reach $nextLevel',
            style: AppText.captionMuted.copyWith(fontSize: 11, color: const Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.prefs, required this.onToggle});
  final Set<String> prefs;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Job preferences',
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
                height: 1.15,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _categories
                  .map((c) => _PrefChip(
                        label: c,
                        selected: prefs.contains(c),
                        onTap: () => onToggle(c),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefChip extends StatelessWidget {
  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink900 : Colors.white,
            border: Border.all(
              color: selected ? AppColors.ink900 : const Color(0xFFEEEEEE),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppText.body.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.0,
              color: selected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ink900,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(
            right: -8,
            top: -8,
            child: Opacity(
              opacity: 0.08,
              child: Text('✨', style: TextStyle(fontSize: 60)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ Go Premium',
                style: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Get priority alerts, unlimited saves & verified badge',
                style: AppText.captionMuted.copyWith(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Upgrade — ₹99/mo',
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == items.length - 1 ? Colors.transparent : AppColors.ink50,
                  ),
                ),
              ),
              child: items[i],
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.bg,
    this.danger = false,
    this.onTap,
  });

  final String icon;
  final String label;
  final Color bg;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: danger ? AppColors.danger : const Color(0xFF222222),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFFDDDDDD)),
          ],
        ),
      ),
    );
  }
}
