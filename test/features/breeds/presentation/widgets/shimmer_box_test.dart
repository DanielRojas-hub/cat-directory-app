import 'package:cat_directory_app/core/theme/app_theme.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/shimmer_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  List<Color?> readShimmerColors(WidgetTester tester) {
    final containerFinder = find.descendant(
      of: find.byType(ShimmerBox),
      matching: find.byType(Container),
    );
    return tester
        .widgetList<Container>(containerFinder)
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .toList();
  }

  group('ShimmerScope & ShimmerBox', () {
    testWidgets(
        'BreedsSkeletonList shares one AnimationController across all 24 ShimmerBoxes and pulses in sync',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: BreedsSkeletonList(itemCount: 8),
          ),
        ),
      );

      expect(find.byType(ShimmerScope), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(24));

      final animatedBuilders = tester
          .widgetList<AnimatedBuilder>(
            find.descendant(
              of: find.byType(ShimmerBox),
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .toList();

      expect(animatedBuilders, hasLength(24));
      final sharedAnimation = animatedBuilders.first.listenable;
      expect(sharedAnimation, isA<AnimationController>());
      for (final builder in animatedBuilders) {
        expect(identical(builder.listenable, sharedAnimation), isTrue);
      }

      final initialColors = readShimmerColors(tester);
      expect(initialColors, hasLength(24));
      expect(initialColors.toSet(), hasLength(1));

      await tester.pump(const Duration(milliseconds: 550));

      final midColors = readShimmerColors(tester);
      expect(midColors, hasLength(24));
      expect(midColors.toSet(), hasLength(1));
      expect(midColors.first, isNot(equals(initialColors.first)));

      // Unmount cleanly without leaving active tickers.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets(
        'FactSkeleton shares one AnimationController across its 3 ShimmerBoxes and pulses in sync',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: FactSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerScope), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(3));

      final animatedBuilders = tester
          .widgetList<AnimatedBuilder>(
            find.descendant(
              of: find.byType(ShimmerBox),
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .toList();

      expect(animatedBuilders, hasLength(3));
      final sharedAnimation = animatedBuilders.first.listenable;
      expect(sharedAnimation, isA<AnimationController>());
      for (final builder in animatedBuilders) {
        expect(identical(builder.listenable, sharedAnimation), isTrue);
      }

      final initialColors = readShimmerColors(tester);
      expect(initialColors.toSet(), hasLength(1));

      await tester.pump(const Duration(milliseconds: 550));

      final midColors = readShimmerColors(tester);
      expect(midColors.toSet(), hasLength(1));
      expect(midColors.first, isNot(equals(initialColors.first)));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('ShimmerBox supports an explicit Animation<double> parameter',
        (tester) async {
      const externalAnimation = AlwaysStoppedAnimation<double>(0.5);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: ShimmerBox(
              width: 120,
              height: 16,
              animation: externalAnimation,
            ),
          ),
        ),
      );

      final builder = tester.widget<AnimatedBuilder>(
        find.descendant(
          of: find.byType(ShimmerBox),
          matching: find.byType(AnimatedBuilder),
        ),
      );
      expect(identical(builder.listenable, externalAnimation), isTrue);
    });

    testWidgets('standalone ShimmerBox falls back to a local pulsing controller',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: ShimmerBox(width: 100, height: 14),
          ),
        ),
      );

      final initialColor = readShimmerColors(tester).single;
      await tester.pump(const Duration(milliseconds: 550));
      final midColor = readShimmerColors(tester).single;

      expect(midColor, isNot(equals(initialColor)));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
