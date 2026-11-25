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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? _paletteDark : _paletteLight;
    final bgColor = palette[breed.breed.hashCode.abs() % palette.length];
    final fgColor = isDark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final badge = ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Text(
          breed.initials,
          style: theme.textTheme.titleMedium?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
            letterSpacing: 0.4,
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
