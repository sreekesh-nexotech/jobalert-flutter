import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/listing.dart';
import '../listings_controller.dart';

/// The Home tab — greeting + warm "12 new postings" banner + two quick
/// access cards + horizontally-scrolling Trending Biz row.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onSwitchTab, required this.onScroll});

  final ValueChanged<int> onSwitchTab;
  final ValueChanged<double> onScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final feed = ref.watch(homeFeedProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning ☀️'
        : hour < 17
            ? 'Good afternoon 🌤️'
            : 'Good evening 🌙';

    final newCount =
        feed.maybeWhen(data: (m) => (m['new_jobs_count'] as int?) ?? 0, orElse: () => 0);
    final unread =
        feed.maybeWhen(data: (m) => (m['unread_notifications'] as int?) ?? 0, orElse: () => 0);
    final trending = feed.maybeWhen<List<Listing>>(
      data: (m) {
        final raw = (m['trending_biz'] as List?) ?? const [];
        return raw.cast<Map<String, dynamic>>().map((j) => Listing.fromJson(j, ListingType.biz)).toList();
      },
      orElse: () => const [],
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) onScroll(n.metrics.pixels);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppText.captionMuted.copyWith(
                      fontSize: 12,
                      color: AppColors.ink400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.displayName ?? 'Welcome',
                    style: AppText.h1.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.03 * 24,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Here's what's new for you today",
                    style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink300),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _NewListingsBanner(
                count: newCount,
                onTap: () => onSwitchTab(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickCard(
                      label: 'All Jobs',
                      sub: 'Browse openings',
                      icon: Icons.work_outline,
                      bg: AppColors.beigeBg,
                      iconBg: const Color(0x1F8B7355),
                      iconColor: AppColors.ink800,
                      onTap: () => onSwitchTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickCard(
                      label: 'Saved Jobs',
                      sub: '$unread unread',
                      icon: Icons.bookmark_border,
                      bg: AppColors.sageBg,
                      iconBg: const Color(0x1F5A7A52),
                      iconColor: AppColors.sage,
                      labelColor: AppColors.sage,
                      onTap: () => onSwitchTab(1),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Trending Biz', style: AppText.sectionTitle)),
                  GestureDetector(
                    onTap: () => onSwitchTab(2),
                    child: Text(
                      'View all',
                      style: AppText.captionMuted.copyWith(
                        fontSize: 12,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _BizBannerCard(
                  listing: trending[i],
                  onTap: () => context.push('/detail/biz/${trending[i].uid}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewListingsBanner extends StatelessWidget {
  const _NewListingsBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.peachBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0x21C8783A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 NEW LISTINGS',
                  style: AppText.captionMuted.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                    letterSpacing: 0.08 * 10,
                  ),
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 195),
                  child: Text(
                    'Check out $count new job postings you might be eligible for',
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      color: AppColors.ink900,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      letterSpacing: -0.02 * 15,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: AppText.captionMuted.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 11, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.sub,
    required this.icon,
    required this.bg,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.labelColor,
  });
  final String label;
  final String sub;
  final IconData icon;
  final Color bg;
  final Color iconBg;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppText.cardTitle.copyWith(
                fontSize: 13,
                color: labelColor ?? AppColors.ink900,
              ),
            ),
            const SizedBox(height: 2),
            Text(sub, style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink500)),
          ],
        ),
      ),
    );
  }
}

class _BizBannerCard extends StatelessWidget {
  const _BizBannerCard({required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.ink100),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0E000000), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 110,
                child: listing.thumbnailUrl.isEmpty
                    ? Container(color: AppColors.ink100)
                    : CachedNetworkImage(
                        imageUrl: listing.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.ink100),
                        errorWidget: (_, __, ___) => Container(color: AppColors.ink100),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                        height: 1.35,
                        letterSpacing: -0.01 * 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    if (listing.investmentDisplay.isNotEmpty)
                      Text(
                        listing.investmentDisplay,
                        style: AppText.captionMuted.copyWith(fontSize: 10, color: AppColors.sage),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
