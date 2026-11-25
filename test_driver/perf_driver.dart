import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data != null && data.containsKey('scroll_performance')) {
        final timeline = driver.Timeline.fromJson(
          data['scroll_performance'] as Map<String, dynamic>,
        );
        final summary = driver.TimelineSummary.summarize(timeline);
        await summary.writeTimelineToFile(
          'scroll_performance',
          destinationDirectory: 'docs/performance',
          pretty: true,
        );
        // Keep only the compact summary JSON in git (drop raw multi-MB trace).
        final rawTrace = File('docs/performance/scroll_performance.timeline.json');
        if (rawTrace.existsSync()) {
          await rawTrace.delete();
        }

        // Enforce real TimelineSummary budgets (>200 captured frames, 0 jank).
        final metrics = summary.summaryJson;
        final frameCount = (metrics['frame_count'] as num?)?.toInt() ?? 0;
        final missedBuild =
            (metrics['missed_frame_build_budget_count'] as num?)?.toInt() ?? -1;
        final missedRaster =
            (metrics['missed_frame_rasterizer_budget_count'] as num?)?.toInt() ??
                -1;

        if (frameCount <= 200) {
          throw StateError(
            'Expected >200 captured scroll frames in TimelineSummary, got $frameCount.',
          );
        }
        if (missedBuild != 0 || missedRaster != 0) {
          throw StateError(
            'Jank detected in TimelineSummary: '
            'missedBuild=$missedBuild, missedRaster=$missedRaster.',
          );
        }
      }
    },
    onScreenshot: (name, image, [args]) async {
      final file = File('docs/performance/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(image);
      return true;
    },
  );
}
