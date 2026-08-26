import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerPlaceholder.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerPlaceholder.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
    this.baseColor,
    this.highlightColor,
  });

  ShimmerPlaceholder.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = 12,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: baseColor ?? Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}
