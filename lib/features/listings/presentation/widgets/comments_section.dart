import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/listings_repository.dart';
import '../../data/models/listing.dart';
import '../listings_controller.dart';
import '_relative_time.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.type, required this.uid});
  final ListingType type;
  final String uid;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  bool _open = false;
  final _input = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ref.read(listingsRepositoryProvider).postComment(
            type: widget.type,
            listingUid: widget.uid,
            text: text,
          );
      _input.clear();
      ref.invalidate(commentsProvider((type: widget.type, uid: widget.uid)));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commentsProvider((type: widget.type, uid: widget.uid)));
    final count = async.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '💬 Comments ($count)',
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.ink400,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Could not load comments', style: AppText.captionMuted),
              ),
              data: (comments) => Column(
                children: [
                  for (final c in comments) _CommentTile(comment: c),
                  if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Be the first to comment',
                        style: AppText.captionMuted,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.ink900,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _post(),
                        style: AppText.body.copyWith(fontSize: 12, height: 1.0),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Add a comment…',
                          hintStyle: AppText.captionMuted.copyWith(fontSize: 12),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(color: AppColors.ink100, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _posting ? null : _post,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink900,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      _posting ? '…' : 'Post',
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({required this.comment});
  final ListingComment comment;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late int _likes = widget.comment.likesCount;
  late bool _liked = widget.comment.likedByMe;

  void _toggle() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              c.userInitials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.userName,
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      relativeTime(c.createdAt),
                      style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  c.text,
                  style: AppText.body.copyWith(fontSize: 12, color: AppColors.ink700, height: 1.55),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _toggle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        size: 13,
                        color: _liked ? AppColors.brand : AppColors.ink400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$_likes',
                        style: AppText.captionMuted.copyWith(
                          fontSize: 11,
                          color: AppColors.ink400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
