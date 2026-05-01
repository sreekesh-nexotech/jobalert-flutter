import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/listing.dart';
import '_relative_time.dart';

/// The big rectangular card used on the Jobs/Biz tabs.
///
/// Mirrors `.listing-card` from the design — 18-px radius, soft shadow,
/// 16:7 thumb with floating label pills, save button and animated upvote
/// pill, then a 14-px-padded body with title / category / meta-pills /
/// tags / footer row.
class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onOpen,
    this.onUpvoteToggle,
    this.onSaveToggle,
  });

  final Listing listing;
  final VoidCallback onOpen;
  final ValueChanged<bool>? onUpvoteToggle;
  final ValueChanged<bool>? onSaveToggle;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard>
    with SingleTickerProviderStateMixin {
  late int _votes = widget.listing.upvotesCount;
  late bool _voted = widget.listing.upvotedByMe;
  late bool _saved = widget.listing.savedByMe;

  late final AnimationController _voteAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _voteAnim.dispose();
    super.dispose();
  }

  void _toggleVote() {
    setState(() {
      _voted = !_voted;
      _votes += _voted ? 1 : -1;
    });
    _voteAnim
      ..reset()
      ..forward();
    widget.onUpvoteToggle?.call(_voted);
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    widget.onSaveToggle?.call(_saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return Opacity(
      opacity: l.isExpired ? 0.52 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 14,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _thumb(),
                  _body(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb() {
    final l = widget.listing;
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (l.thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: l.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.ink100),
              errorWidget: (_, __, ___) => Container(color: AppColors.ink100),
            )
          else
            Container(color: AppColors.ink100),
          // Labels (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: Wrap(
              spacing: 5,
              children: l.labels
                  .map((lab) => _LabelPill(text: lab.text, bg: lab.bg, fg: lab.fg))
                  .toList(),
            ),
          ),
          // Save button (top-right)
          Positioned(
            top: 10,
            right: 10,
            child: _RoundIconButton(
              onTap: _toggleSave,
              child: Icon(
                _saved ? Icons.bookmark : Icons.bookmark_border,
                size: 16,
                color: _saved ? AppColors.brand : AppColors.ink700,
              ),
            ),
          ),
          // Upvote pill (bottom-left)
          Positioned(
            bottom: 10,
            left: 10,
            child: ScaleTransition(
              scale: TweenSequence<double>([
                TweenSequenceItem(tween: Tween(begin: 1, end: 1.5), weight: 40),
                TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.88), weight: 30),
                TweenSequenceItem(tween: Tween(begin: 0.88, end: 1), weight: 30),
              ]).animate(_voteAnim),
              child: GestureDetector(
                onTap: _toggleVote,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
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
                        size: 18,
                        color: _voted ? AppColors.brand : AppColors.ink500,
                      ),
                      const SizedBox(width: 1),
                      Text(
                        '$_votes',
                        style: AppText.captionMuted.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _voted ? AppColors.brand : AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final l = widget.listing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.title,
            style: AppText.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          _categoryRow(l),
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: _metaPills(l)),
          if (l.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: l.tags.map(_TagPill.new).toList()),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.ink100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.isExpired ? '⚠️ Unverified info' : 'Posted ${relativeTime(l.createdAt)}',
                    style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400),
                  ),
                ),
                if (l.type == ListingType.job && !l.isExpired && l.applicationDeadline != null)
                  Text(
                    'Due ${_dateLabel(l.applicationDeadline!)}',
                    style: AppText.captionMuted.copyWith(
                      fontSize: 11,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (l.sourceName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(Listing l) {
    final parts = <String>[
      l.category,
      if (l.subCategory.isNotEmpty) l.subCategory,
      if (l.type == ListingType.job && l.qualification.isNotEmpty) l.qualification,
    ];
    return Text(
      parts.join(' › '),
      style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _metaPills(Listing l) {
    if (l.type == ListingType.job) {
      return [
        if (l.location.isNotEmpty)
          _MetaPill(icon: Icons.location_on_outlined, label: l.location),
        if (l.experienceLevel.isNotEmpty) _MetaPill(label: l.experienceLevel),
        if (l.salaryDisplay.isNotEmpty)
          _MetaPill(label: l.salaryDisplay, highlight: true),
      ];
    }
    return [
      if (l.opportunityType.isNotEmpty) _MetaPill(label: l.opportunityType),
      if (l.investmentDisplay.isNotEmpty)
        _MetaPill(label: l.investmentDisplay, sage: true),
      if (l.dateInfo.isNotEmpty) _MetaPill(label: '📅 ${l.dateInfo}'),
    ];
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppText.captionMuted.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.02 * 10,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEBFFFFFF),
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Center(child: child)),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({this.icon, required this.label, this.highlight = false, this.sage = false});
  final IconData? icon;
  final String label;
  final bool highlight;
  final bool sage;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? AppColors.peachBg : sage ? AppColors.sageBg : const Color(0xFFF7F7F7);
    final fg = highlight ? AppColors.brand : sage ? AppColors.sage : const Color(0xFF555555);
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
          Text(
            label,
            style: AppText.captionMuted.copyWith(fontSize: 11, color: fg),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.tag);
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink500),
      ),
    );
  }
}
