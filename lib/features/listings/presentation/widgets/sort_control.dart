import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// "Sort: Most Recent ▾" button + dropdown menu, styled to match the prototype.
class SortControl extends StatelessWidget {
  const SortControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => options
          .map(
            (o) => PopupMenuItem(
              value: o,
              height: 42,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      o,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        color: o == value ? AppColors.brand : AppColors.ink800,
                        fontWeight: o == value ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (o == value)
                    const Icon(Icons.check, size: 14, color: AppColors.brand),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 12, color: AppColors.ink800),
            const SizedBox(width: 5),
            Text(
              'Sort: $value',
              style: AppText.captionMuted.copyWith(
                fontSize: 12,
                color: AppColors.ink800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
