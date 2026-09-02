import 'package:flutter/material.dart';

/// Lightweight animated pulse shimmer skeleton for lists and cards without extra dependencies.
class AppShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmerSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<AppShimmerSkeleton> createState() => _AppShimmerSkeletonState();
}

class _AppShimmerSkeletonState extends State<AppShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Pre-built Skeleton Card placeholder for list items
class AppListSkeleton extends StatelessWidget {
  final int count;

  const AppListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppShimmerSkeleton(
                      width: 44,
                      height: 44,
                      borderRadius: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppShimmerSkeleton(width: 160, height: 16),
                          SizedBox(height: 8),
                          AppShimmerSkeleton(width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const AppShimmerSkeleton(height: 14),
                const SizedBox(height: 6),
                const AppShimmerSkeleton(width: 220, height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}
