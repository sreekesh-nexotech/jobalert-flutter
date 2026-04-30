import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/listings_repository.dart';
import '../../data/models/listing.dart';

const _reasons = <String>[
  'Incorrect information',
  'Duplicate listing',
  'Spam or misleading',
  'Expired / outdated',
  'Other',
];

/// Bottom-sheet report dialog: a list of radio reasons + Cancel/Submit row.
/// On submit it posts to `/reports/` and switches to a confirmation view.
class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({super.key, required this.type, required this.uid});
  final ListingType type;
  final String uid;

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selected;
  bool _submitting = false;
  bool _done = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(listingsRepositoryProvider).reportListing(
            type: widget.type,
            uid: widget.uid,
            reason: _wireFor(_selected!),
          );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      // Surface non-fatally — the user can dismiss and retry.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _wireFor(String label) => switch (label) {
        'Incorrect information' => 'incorrect_info',
        'Duplicate listing' => 'duplicate',
        'Spam or misleading' => 'spam',
        'Expired / outdated' => 'expired',
        _ => 'other',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: _done ? _confirmation() : _form(),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report this listing',
          style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Why are you reporting this?',
          style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink400),
        ),
        const SizedBox(height: 16),
        for (final r in _reasons)
          InkWell(
            onTap: () => setState(() => _selected = r),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: r == _reasons.last ? Colors.transparent : AppColors.ink100,
                  ),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selected == r ? AppColors.brand : const Color(0xFFDDDDDD),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _selected == r ? 8 : 0,
                        height: _selected == r ? 8 : 0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(r, style: AppText.body.copyWith(fontSize: 13, color: AppColors.ink800)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink100,
                  foregroundColor: AppColors.ink700,
                  elevation: 0,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: AppText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _selected == null || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink900,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Submit',
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _confirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✅', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text('Report submitted', style: AppText.h3),
        const SizedBox(height: 4),
        Text(
          'Our team will review this listing shortly.',
          style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink400),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink900,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Done',
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
