import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/listings_repository.dart';
import '../../data/models/listing.dart';
import '../listings_controller.dart';
import '../widgets/comments_section.dart';
import '../widgets/report_dialog.dart';
import '../widgets/_relative_time.dart';

/// Listing detail — slide-in screen with hero thumb, body, comments, and a
/// pinned bottom CTA row (Apply / Enquire). Mirrors `.detail-screen` from
/// the design.
class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.type, required this.uid});

  final String type;
  final String uid;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  late final ListingType _type = ListingType.fromString(widget.type);

  @override
  void initState() {
    super.initState();
    // Fire-and-forget view tracking after first frame (treat as view event).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final listing = await ref.read(
          listingDetailProvider((type: _type, uid: widget.uid)).future,
        );
        await ref.read(listingsRepositoryProvider).trackView(listing);
      } catch (_) {/* best-effort */}
    });
  }

  Future<void> _shareIfAvailable(Listing l) async {
    final text = '${l.title}\n\n${l.sourceUrl.isNotEmpty ? l.sourceUrl : ''}';
    await Share.share(text.trim(), subject: l.title);
  }

  Future<void> _apply(Listing l) async {
    if (l.sourceUrl.isNotEmpty) {
      await launchUrl(Uri.parse(l.sourceUrl), mode: LaunchMode.externalApplication);
    }
    await ref.read(listingsRepositoryProvider).markApplied(l);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.type == ListingType.job ? 'Marked as applied' : 'Marked as enquired'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openReport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x80000000),
      builder: (_) => ReportDialog(type: _type, uid: widget.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider((type: _type, uid: widget.uid)));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load listing.\n$e', style: AppText.body, textAlign: TextAlign.center),
            ),
          ),
          data: (l) => _Detail(
            listing: l,
            onShare: () => _shareIfAvailable(l),
            onReport: _openReport,
            onApply: () => _apply(l),
          ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({
    required this.listing,
    required this.onShare,
    required this.onReport,
    required this.onApply,
  });

  final Listing listing;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onApply;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  late bool _saved = widget.listing.savedByMe;

  Future<void> _toggleSave() async {
    setState(() => _saved = !_saved);
    try {
      await ref.read(listingsRepositoryProvider).toggleSave(widget.listing);
    } catch (_) {
      if (mounted) setState(() => _saved = !_saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return Column(
      children: [
        _Header(title: l.title, onShare: widget.onShare, onReport: widget.onReport),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(l: l),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        style: AppText.h2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.025 * 18,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l.category} › ${l.subCategory}',
                        style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink400),
                      ),
                      const SizedBox(height: 12),
                      _MetaRow(l: l),
                      if (l.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: l.tags
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.ink100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    t,
                                    style: AppText.captionMuted.copyWith(
                                      fontSize: 11,
                                      color: AppColors.ink500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.ink50)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Posted ${relativeTime(l.createdAt)}',
                              style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400),
                            ),
                            if (l.sourceName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text('·', style: AppText.captionMuted),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.ink100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l.sourceName,
                                  style: AppText.captionMuted.copyWith(
                                    fontSize: 11,
                                    color: AppColors.ink500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (l.isExpired) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '⚠️ Unverified',
                                  style: AppText.captionMuted.copyWith(
                                    fontSize: 10,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.type == ListingType.job
                            ? '📋 About this role'
                            : '📋 About this opportunity',
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.description,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: AppColors.ink700,
                          height: 1.7,
                        ),
                      ),
                      CommentsSection(type: l.type, uid: l.uid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomActions(
          isJob: l.type == ListingType.job,
          saved: _saved,
          onToggleSave: _toggleSave,
          onApply: widget.onApply,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onShare, required this.onReport});
  final String title;
  final VoidCallback onShare;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink50)),
      ),
      child: Row(
        children: [
          _RoundButton(onTap: () => Navigator.of(context).pop(), icon: Icons.arrow_back),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
                letterSpacing: -0.01 * 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _RoundButton(onTap: onShare, icon: Icons.share_outlined, size: 32),
          const SizedBox(width: 6),
          _RoundButton(onTap: onReport, icon: Icons.flag_outlined, size: 32),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, required this.icon, this.size = 34});
  final VoidCallback onTap;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F7),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.ink800),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.l});
  final Listing l;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 190,
          child: l.thumbnailUrl.isEmpty
              ? Container(color: AppColors.ink100)
              : CachedNetworkImage(
                  imageUrl: l.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.ink100),
                  errorWidget: (_, __, ___) => Container(color: AppColors.ink100),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Wrap(
            spacing: 6,
            children: l.labels
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
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.l});
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    if (l.type == ListingType.job) {
      if (l.location.isNotEmpty) pills.add(_pill(Icons.location_on_outlined, l.location));
      if (l.experienceLevel.isNotEmpty) pills.add(_pill(null, l.experienceLevel));
      if (l.salaryDisplay.isNotEmpty) pills.add(_pill(null, l.salaryDisplay, peach: true));
      if (l.applicationDeadline != null) pills.add(_pill(null, '📅 ${_dateLabel(l.applicationDeadline!)}'));
    } else {
      if (l.opportunityType.isNotEmpty) pills.add(_pill(null, l.opportunityType));
      if (l.investmentDisplay.isNotEmpty) pills.add(_pill(null, l.investmentDisplay, sage: true));
      if (l.venue.isNotEmpty) pills.add(_pill(null, '📍 ${l.venue}'));
      if (l.dateInfo.isNotEmpty) pills.add(_pill(null, '📅 ${l.dateInfo}'));
    }
    return Wrap(spacing: 5, runSpacing: 5, children: pills);
  }

  Widget _pill(IconData? icon, String text, {bool peach = false, bool sage = false}) {
    final bg = peach ? AppColors.peachBg : sage ? AppColors.sageBg : AppColors.ink100;
    final fg = peach ? AppColors.brand : sage ? AppColors.sage : AppColors.ink700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppText.captionMuted.copyWith(fontSize: 11, color: fg)),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isJob,
    required this.saved,
    required this.onToggleSave,
    required this.onApply,
  });
  final bool isJob;
  final bool saved;
  final VoidCallback onToggleSave;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink50)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggleSave,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                saved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: saved ? AppColors.brand : AppColors.ink800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink900,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isJob ? 'Apply Now' : 'Enquire Now',
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
