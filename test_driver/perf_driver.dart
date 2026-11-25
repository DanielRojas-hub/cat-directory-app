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
