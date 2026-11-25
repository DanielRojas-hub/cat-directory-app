import 'package:cat_directory_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// End-to-end scroll performance audit driving infinite scroll through all pages
/// and capturing frame timing telemetry via [IntegrationTestWidgetsFlutterBinding].
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Infinite scroll stays jank-free across all loaded pages',
      (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    await binding.traceAction(() async {
      // Scroll through pages to load all 98 breeds and exercise SliverList recycling.
      for (var i = 0; i < 14; i++) {
        await tester.fling(scrollable, const Offset(0, -900), 1800);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));
      }

      // Sustained rapid scroll up & down with the full directory in memory.
      for (var i = 0; i < 6; i++) {
        await tester.fling(scrollable, const Offset(0, 950), 2200);
        await tester.pump(const Duration(milliseconds: 250));
      }
      for (var i = 0; i < 6; i++) {
        await tester.fling(scrollable, const Offset(0, -950), 2200);
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
      await binding.takeScreenshot('performance_overlay_scroll');
    }, reportKey: 'scroll_performance');
  });
}
