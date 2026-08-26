import 'package:flutter/material.dart';
import 'shimmer_placeholder.dart';

class PageLoadingWrapper extends StatefulWidget {
  final Widget child;
  final bool? isLoading;

  const PageLoadingWrapper({
    super.key,
    required this.child,
    this.isLoading,
  });

  @override
  State<PageLoadingWrapper> createState() => _PageLoadingWrapperState();
}

class _PageLoadingWrapperState extends State<PageLoadingWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate network delay for a prototype shimmer effect
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool currentLoading = _isLoading || (widget.isLoading ?? false);
    if (!currentLoading) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: ShimmerPlaceholder.rounded(
          height: 20,
          width: 150,
          borderRadius: 4,
        ),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar placeholder
            ShimmerPlaceholder.rounded(height: 50, borderRadius: 16),
            const SizedBox(height: 24),
            // Horizontal items placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    const ShimmerPlaceholder.circular(height: 70, width: 70),
                    const SizedBox(height: 8),
                    ShimmerPlaceholder.rounded(
                      height: 12,
                      width: 50,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Section title placeholder
            ShimmerPlaceholder.rounded(height: 24, width: 200, borderRadius: 4),
            const SizedBox(height: 16),
            // Vertical cards placeholder
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ShimmerPlaceholder.rounded(
                  height: 120,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
