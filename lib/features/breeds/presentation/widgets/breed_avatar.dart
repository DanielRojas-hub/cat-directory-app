import 'package:material_ui/material_ui.dart';

import '../../domain/entities/breed.dart';

/// Generates a stable Hero tag for transitions between list and detail screens.
String breedHeroTag(String breedName) => 'breed-avatar-${breedName.toLowerCase()}';

/// Deterministic, zero-image monogram avatar with Hero transition support.
class BreedAvatar extends StatelessWidget {
  const BreedAvatar({
    super.key,
    required this.breed,
    this.size = 48,
    this.enableHero = true,
  });

  final Breed breed;
  final double size;
  final bool enableHero;

  static const List<Color> _paletteLight = [
    Color(0xFFFFE0CC),
    Color(0xFFD7F0E3),
    Color(0xFFDDE8FF),
    Color(0xFFF6E0F5),
    Color(0xFFFFF0C2),
    Color(0xFFD6F3F3),
  ];

  static const List<Color> _paletteDark = [
    Color(0xFF5A3118),
    Color(0xFF1E4A36),
    Color(0xFF213A63),
    Color(0xFF51284F),
    Color(0xFF574417),
    Color(0xFF1A4B4D),
  ];

  /// Computes a deterministic palette index from [breedName] UTF-16 code units
  /// so avatar colors remain stable across process restarts and platforms.
  static int paletteIndexFor(String breedName, {int paletteLength = 6}) {
    var hash = 0;
    for (final unit in breedName.codeUnits) {
      hash = (hash * 17 + unit) & 0x7fffffff;
    }
    return hash % paletteLength;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? _paletteDark : _paletteLight;
    final bgColor = palette[paletteIndexFor(
      breed.breed,
      paletteLength: palette.length,
    )];
    final fgColor = isDark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final badge = ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            breed.initials,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.titleMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );

    if (!enableHero) {
      return badge;
    }

    return Hero(
      tag: breedHeroTag(breed.breed),
      child: Material(
        type: MaterialType.transparency,
        child: badge,
      ),
    );
  }
}
