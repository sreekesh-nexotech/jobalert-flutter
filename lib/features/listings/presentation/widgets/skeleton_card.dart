import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';

/// Loading-state placeholder that mirrors `.skeleton` card shape from the
/// design. Three of these are shown while the first list page loads.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: const Color(0xFFE6E6E6),
      period: const Duration(milliseconds: 1400),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(height: 130, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(height: 13, widthFactor: 0.8),
                  const SizedBox(height: 6),
                  _bar(height: 11, widthFactor: 0.52),
                  const SizedBox(height: 8),
                  Row(children: [
                    _bar(height: 22, width: 56, radius: 999),
                    const SizedBox(width: 6),
                    _bar(height: 22, width: 68, radius: 999),
                    const SizedBox(width: 6),
                    _bar(height: 22, width: 76, radius: 999),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({double? height, double? width, double widthFactor = 1, double radius = 8}) {
    return FractionallySizedBox(
      widthFactor: width == null ? widthFactor : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
