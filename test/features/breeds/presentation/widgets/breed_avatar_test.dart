import 'package:cat_directory_app/core/theme/app_theme.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/breed_avatar.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/breed_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const sampleBreed = Breed(
    breed: 'Abyssinian',
    country: 'Ethiopia',
    origin: 'Natural/Standard',
    coat: 'Short',
    pattern: 'Ticked',
  );

  const wideInitialsBreed = Breed(
    breed: 'Wild Whisker',
    country: 'United States',
    origin: 'Natural',
    coat: 'Short',
    pattern: 'Tabby',
  );

  group('BreedAvatar', () {
    test('paletteIndexFor is deterministic and bounded across calls', () {
      final first = BreedAvatar.paletteIndexFor('Abyssinian');
      final second = BreedAvatar.paletteIndexFor('Abyssinian');
      expect(first, equals(second));
      expect(first, inInclusiveRange(0, 5));

      final indices = [
        'Abyssinian',
        'Aegean',
        'Bengal',
        'Birman',
        'Bombay',
        'Persian',
        'Siamese',
        'Somali',
      ].map(BreedAvatar.paletteIndexFor).toSet();

      expect(indices.length, greaterThan(1));
      for (final index in indices) {
        expect(index, inInclusiveRange(0, 5));
      }
    });

    testWidgets('renders identical deterministic color in light and dark modes',
        (tester) async {
      Color? extractAvatarColor() {
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(BreedAvatar),
            matching: find.byType(Container),
          ),
        );
        return (container.decoration as BoxDecoration?)?.color;
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: BreedAvatar(breed: sampleBreed, enableHero: false),
          ),
        ),
      );
      final lightColorFirst = extractAvatarColor();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: BreedAvatar(breed: sampleBreed, enableHero: false),
          ),
        ),
      );
      final lightColorSecond = extractAvatarColor();
      expect(lightColorFirst, isNotNull);
      expect(lightColorFirst, equals(lightColorSecond));

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark-theme-app-1'),
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: BreedAvatar(breed: sampleBreed, enableHero: false),
          ),
        ),
      );
      final darkColorFirst = extractAvatarColor();

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark-theme-app-2'),
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: BreedAvatar(breed: sampleBreed, enableHero: false),
          ),
        ),
      );
      final darkColorSecond = extractAvatarColor();
      expect(darkColorFirst, isNotNull);
      expect(darkColorFirst, equals(darkColorSecond));
      expect(darkColorFirst, isNot(equals(lightColorFirst)));
    });

    testWidgets(
        'wraps initials in FittedBox(scaleDown) without overflow or clipping at 1.5x and 2.0x textScaler',
        (tester) async {
      for (final scale in const [1.5, 2.0]) {
        for (final avatarSize in const [48.0, 72.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                );
              },
              home: Scaffold(
                body: Center(
                  child: BreedAvatar(
                    breed: wideInitialsBreed,
                    size: avatarSize,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);

          final fittedBox = tester.widget<FittedBox>(
            find.descendant(
              of: find.byType(BreedAvatar),
              matching: find.byType(FittedBox),
            ),
          );
          expect(fittedBox.fit, BoxFit.scaleDown);

          final avatarRect = tester.getRect(find.byType(BreedAvatar));
          final fittedRect = tester.getRect(
            find.descendant(
              of: find.byType(BreedAvatar),
              matching: find.byType(FittedBox),
            ),
          );

          expect(avatarRect.width, closeTo(avatarSize, 0.01));
          expect(avatarRect.height, closeTo(avatarSize, 0.01));
          expect(fittedRect.left, greaterThanOrEqualTo(avatarRect.left));
          expect(fittedRect.top, greaterThanOrEqualTo(avatarRect.top));
          expect(fittedRect.right, lessThanOrEqualTo(avatarRect.right));
          expect(fittedRect.bottom, lessThanOrEqualTo(avatarRect.bottom));
        }
      }
    });

    testWidgets(
        'Hero transition from list (48px) to detail (72px) has zero overflow at 2.0x textScaler',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: BreedCard(
                  breed: wideInitialsBreed,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: Center(
                            child: BreedAvatar(
                              breed: wideInitialsBreed,
                              size: 72,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(BreedCard));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Step through intermediate Hero flight frames (48px -> 72px).
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        expect(find.byType(FittedBox), findsAtLeastNWidgets(1));
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final detailRect = tester.getRect(find.byType(BreedAvatar));
      expect(detailRect.width, closeTo(72, 0.01));
      expect(detailRect.height, closeTo(72, 0.01));

      // Pop back and inspect reverse Hero flight (72px -> 48px).
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
