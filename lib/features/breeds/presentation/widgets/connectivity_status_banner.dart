import 'package:material_ui/material_ui.dart';

/// Displays subtle, non-blocking offline, cache-age and SWR revalidation cues.
class ConnectivityStatusBanner extends StatelessWidget {
  const ConnectivityStatusBanner({
    super.key,
    required this.isOnline,
    required this.isFromCache,
    required this.isRevalidating,
    required this.lastSyncedAt,
    required this.onRetry,
  });

  final bool isOnline;
  final bool isFromCache;
  final bool isRevalidating;
  final DateTime? lastSyncedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isOnline) {
      final ageLabel = _formatAge(lastSyncedAt);
      return _BannerContainer(
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        icon: Icons.wifi_off_rounded,
        text: ageLabel != null
            ? 'Sin conexión · Datos guardados ($ageLabel)'
            : 'Sin conexión a internet',
        actionLabel: 'Reintentar',
        onAction: onRetry,
      );
    }

    if (isRevalidating) {
      return Semantics(
        liveRegion: true,
        label: 'Actualizando directorio en segundo plano',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 15,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actualizando directorio en segundo plano...',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isFromCache) {
      final ageLabel = _formatAge(lastSyncedAt);
      return _BannerContainer(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        icon: Icons.offline_pin_outlined,
        text: ageLabel != null
            ? 'Mostrando copia en caché ($ageLabel)'
            : 'Mostrando copia en caché',
        actionLabel: 'Sincronizar',
        onAction: onRetry,
      );
    }

    return const SizedBox.shrink();
  }

  String? _formatAge(DateTime? syncedAt) {
    if (syncedAt == null) return null;
    final diff = DateTime.now().toUtc().difference(syncedAt.toUtc());
    if (diff.inSeconds < 60) return 'hace unos segundos';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}

class _BannerContainer extends StatelessWidget {
  const _BannerContainer({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 18, color: foregroundColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
