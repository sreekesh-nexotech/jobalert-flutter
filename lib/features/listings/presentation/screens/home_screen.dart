import 'dart:math' as math;
import 'dart:ui';

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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onSwitchTab, required this.onScroll});

  final ValueChanged<int> onSwitchTab;
  final ValueChanged<double> onScroll;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glow1 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();
  late final AnimationController _glow2 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  )..repeat();
  late final AnimationController _glow3 = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 13),
  )..repeat();

  @override
  void dispose() {
    _glow1.dispose();
    _glow2.dispose();
    _glow3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final onSwitchTab = widget.onSwitchTab;
    final onScroll = widget.onScroll;
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
    final savedCount =
        feed.maybeWhen(data: (m) => (m['saved_count'] as int?) ?? 0, orElse: () => 0);
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
            // Greeting block with subtle drifting glow blobs.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _GlowBlobs(
                      glow1: _glow1,
                      glow2: _glow2,
                      glow3: _glow3,
                    ),
                  ),
                ),
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
              ],
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
                      sub: '$savedCount saved',
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
              height: 232,
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
            Positioned(
              right: 22,
              bottom: -28,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0x14C8783A),
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

class _BizBannerCard extends StatefulWidget {
  const _BizBannerCard({required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  @override
  State<_BizBannerCard> createState() => _BizBannerCardState();
}

class _BizBannerCardState extends State<_BizBannerCard> {
  late int _votes = widget.listing.upvotesCount;
  late bool _voted = widget.listing.upvotedByMe;

  void _toggleVote() {
    setState(() {
      _voted = !_voted;
      _votes += _voted ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return GestureDetector(
      onTap: widget.onTap,
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (l.thumbnailUrl.isEmpty)
                      Container(color: const Color(0xFFF5F5F5))
                    else
                      CachedNetworkImage(
                        imageUrl: l.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFFF5F5F5)),
                      ),
                    if (l.labels.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          spacing: 4,
                          children: l.labels
                              .take(2)
                              .map(
                                (lab) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: lab.bg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    lab.text,
                                    style: AppText.captionMuted.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: lab.fg,
                                      letterSpacing: 0.02 * 10,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleVote,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
                          decoration: BoxDecoration(
                            color: const Color(0xEBFFFFFF),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_drop_up,
                                size: 16,
                                color: _voted ? AppColors.brand : AppColors.ink500,
                              ),
                              Text(
                                '$_votes',
                                style: AppText.captionMuted.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _voted ? AppColors.brand : AppColors.ink900,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
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
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (l.investmentDisplay.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sageBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.investmentDisplay,
                              style: AppText.captionMuted.copyWith(
                                fontSize: 10,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                        if (l.opportunityType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.opportunityType,
                              style: AppText.captionMuted.copyWith(
                                fontSize: 10,
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _footer(l),
                      style: AppText.captionMuted.copyWith(fontSize: 10, color: AppColors.ink400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _footer(Listing l) {
    final parts = <String>[];
    final posted = l.createdAt;
    parts.add(_relative(posted));
    if (l.sourceName.isNotEmpty) parts.add(l.sourceName);
    return parts.join(' · ');
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    return 'just now';
  }
}

/// Three slowly drifting radial-gradient blobs that sit behind the home
/// greeting block — matches the `glowDrift1/2/3` keyframes in the design.
class _GlowBlobs extends StatelessWidget {
  const _GlowBlobs({
    required this.glow1,
    required this.glow2,
    required this.glow3,
  });

  final Animation<double> glow1;
  final Animation<double> glow2;
  final Animation<double> glow3;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glow1, glow2, glow3]),
      builder: (context, _) {
        final w = MediaQuery.of(context).size.width;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _blob(
              left: w * 0.15 - 90,
              top: 20 + 12 * math.sin(glow1.value * 2 * math.pi),
              size: 180,
              opacity: 0.55 + 0.35 * (math.sin(glow1.value * 2 * math.pi) + 1) / 2,
              color: const Color(0xFFC8783A),
              alpha: 0.09,
            ),
            _blob(
              right: w * 0.05 - 70,
              top: 60 + 14 * math.sin(glow2.value * 2 * math.pi + 1.5),
              size: 140,
              opacity: 0.5 + 0.35 * (math.sin(glow2.value * 2 * math.pi) + 1) / 2,
              color: const Color(0xFF8FA67B),
              alpha: 0.08,
            ),
            _blob(
              left: w * 0.40 - 60,
              top: 120 + 10 * math.sin(glow3.value * 2 * math.pi + 0.8),
              size: 120,
              opacity: 0.4 + 0.3 * (math.sin(glow3.value * 2 * math.pi) + 1) / 2,
              color: const Color(0xFFC8783A),
              alpha: 0.055,
            ),
          ],
        );
      },
    );
  }

  Widget _blob({
    double? left,
    double? right,
    required double top,
    required double size,
    required double opacity,
    required Color color,
    required double alpha,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(alpha),
                  color.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
