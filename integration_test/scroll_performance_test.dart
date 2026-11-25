import 'package:cat_directory_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// End-to-end scroll performance audit driving infinite scroll through all pages
/// (98/98 breeds) and sustaining >200 continuous 60 Hz frames inside
/// [IntegrationTestWidgetsFlutterBinding.traceAction].
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Sustained scroll across all 98 breeds stays jank-free (>200 frames)',
      (tester) async {
    await app.main();

    // Wait for initial page to finish loading without relying on a single fixed delay.
    final scrollable = find.byType(CustomScrollView);
    for (var attempt = 0; attempt < 40 && scrollable.evaluate().isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(scrollable, findsOneWidget);

    // Phase 1: Paginate through the entire directory until all 98 breeds are loaded.
    final endFooter = find.textContaining('Fin del directorio');
    for (var step = 0; step < 35 && endFooter.evaluate().isEmpty; step++) {
      await tester.fling(scrollable, const Offset(0, -1000), 2200);
      for (var p = 0; p < 10 && endFooter.evaluate().isEmpty; p++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }
    expect(endFooter, findsOneWidget);

    // Phase 2: Measure sustained bidirectional scroll across all loaded breeds
    // at 60 Hz frame cadence. Actual frame-count (>200) and zero-jank budgets
    // are asserted on the generated TimelineSummary in test_driver/perf_driver.dart.
    const frameInterval = Duration(milliseconds: 16);

    Future<void> pumpBallisticFrames(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(frameInterval);
      }
    }

    await binding.traceAction(() async {
      for (var cycle = 0; cycle < 2; cycle++) {
        // Sweep upward across the full 98-breed SliverList.
        for (var seg = 0; seg < 2; seg++) {
          await tester.timedDrag(
            scrollable,
            const Offset(0, 1100),
            const Duration(milliseconds: 700),
            frequency: 60.0,
          );
        }
        await tester.fling(scrollable, const Offset(0, 1200), 2400);
        await pumpBallisticFrames(28);

        // Sweep downward back to the bottom of the 98-breed SliverList.
        for (var seg = 0; seg < 2; seg++) {
          await tester.timedDrag(
            scrollable,
            const Offset(0, -1100),
            const Duration(milliseconds: 700),
            frequency: 60.0,
          );
        }
        await tester.fling(scrollable, const Offset(0, -1200), 2400);
        await pumpBallisticFrames(28);
      }

      // Settle briefly at the bottom so 98/98 and the end footer appear crisp.
      await pumpBallisticFrames(12);
    }, reportKey: 'scroll_performance');

    await binding.takeScreenshot('performance_overlay_scroll');
  });
}
