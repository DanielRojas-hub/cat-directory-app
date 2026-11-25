import 'package:material_ui/material_ui.dart';

/// Provides a single shared pulsing [Animation<double>] to descendant
/// [ShimmerBox] widgets so all placeholders animate in sync using one ticker.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
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
    return _ShimmerInherited(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(_ShimmerInherited oldWidget) {
    return animation != oldWidget.animation;
  }
}

/// Lightweight zero-dependency pulsing shimmer placeholder for skeleton states.
///
/// Shares a single [Animation<double>] from an ancestor [ShimmerScope] or an
/// explicitly provided [animation]. Only creates a fallback local controller
/// when mounted standalone without either.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.animation,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Animation<double>? animation;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _fallbackController;
  late Animation<double> _effectiveAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAnimation();
  }

  @override
  void didUpdateWidget(ShimmerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _resolveAnimation();
    }
  }

  void _resolveAnimation() {
    final shared = widget.animation ?? _ShimmerInherited.maybeOf(context);
    if (shared != null) {
      _fallbackController?.stop();
      _effectiveAnimation = shared;
      return;
    }

    final controller = _fallbackController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
    _effectiveAnimation = controller;
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surfaceContainerLow;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _effectiveAnimation,
        builder: (context, child) {
          final color = Color.lerp(
            baseColor,
            highlightColor,
            _effectiveAnimation.value,
          );
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
    return Semantics(
      label: 'Cargando directorio de razas de gatos',
      liveRegion: true,
      excludeSemantics: true,
      child: ShimmerScope(
        child: ListView.separated(
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
        ),
      ),
    );
  }
}

/// Compact skeleton displayed inside the independent Cat Fact card while fetching `/fact`.
class FactSkeleton extends StatelessWidget {
  const FactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando dato curioso aleatorio',
      liveRegion: true,
      excludeSemantics: true,
      child: const ShimmerScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: double.infinity, height: 14),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 14),
            SizedBox(height: 10),
            ShimmerBox(width: 180, height: 14),
          ],
        ),
      ),
    );
  }
}
