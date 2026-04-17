import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final int itemCount;
  const SkeletonLoader({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Shimmer.fromColors(
          baseColor: AppTheme.surface,
          highlightColor: AppTheme.surfaceElevated,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
          ),
        ),
      ),
    );
  }
}
