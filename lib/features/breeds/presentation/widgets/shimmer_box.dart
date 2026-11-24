import 'package:material_ui/material_ui.dart';

/// Lightweight zero-dependency pulsing shimmer placeholder for skeleton states.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surfaceContainerLow;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final color = Color.lerp(baseColor, highlightColor, _controller.value);
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: widget.borderRadius,
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton list rendered during cold-start initial loading (when no cache exists).
class BreedsSkeletonList extends StatelessWidget {
  const BreedsSkeletonList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                ShimmerBox(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160, height: 16),
                      SizedBox(height: 8),
                      ShimmerBox(width: 110, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact skeleton displayed inside the independent Cat Fact card while fetching `/fact`.
class FactSkeleton extends StatelessWidget {
  const FactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 10),
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 10),
        ShimmerBox(width: 180, height: 14),
      ],
    );
  }
}
