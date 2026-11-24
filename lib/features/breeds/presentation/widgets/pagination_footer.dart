import 'package:material_ui/material_ui.dart';

/// Footer rendered below the breeds list to communicate infinite scroll progress,
/// localized intermediate-page failures (preserving loaded items), or end-of-list.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.isSearching,
    required this.loadedCount,
    required this.totalCount,
    required this.errorMessage,
    required this.onRetry,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final bool isSearching;
  final int loadedCount;
  final int totalCount;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando más razas...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Card(
          margin: EdgeInsets.zero,
          color: colorScheme.errorContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No se pudo cargar la siguiente página',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar página'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isSearching && hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          children: [
            Text(
              'Filtrando sobre $loadedCount de $totalCount razas cargadas en memoria',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Cargar más razas'),
            ),
          ],
        ),
      );
    }

    if (!hasMore && loadedCount > 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Fin del directorio · $loadedCount razas exploradas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
