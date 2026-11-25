import 'package:material_ui/material_ui.dart';

import '../../domain/entities/cat_fact.dart';
import '../bloc/breed_detail_state.dart';
import 'shimmer_box.dart';

/// Independent card displaying a random cat fact from `/fact` with its own
/// loading skeleton, localized error handling and refresh action.
class CatFactCard extends StatelessWidget {
  const CatFactCard({
    super.key,
    required this.status,
    required this.fact,
    required this.errorMessage,
    required this.onRefresh,
  });

  final CatFactStatus status;
  final CatFact? fact;
  final String? errorMessage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading =
        status == CatFactStatus.loading || status == CatFactStatus.initial;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Dato Curioso Aleatorio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Cargar otro dato curioso aleatorio',
                  child: IconButton.filledTonal(
                    onPressed: isLoading ? null : onRefresh,
                    tooltip: 'Cargar otro dato curioso',
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              child: switch (status) {
                CatFactStatus.initial || CatFactStatus.loading =>
                  const FactSkeleton(key: ValueKey('fact-loading')),
                CatFactStatus.loaded
                    when (fact?.fact.trim().isNotEmpty ?? false) =>
                  Semantics(
                    key: ValueKey('fact-${fact!.fact.trim()}'),
                    liveRegion: true,
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“${fact!.fact.trim()}”',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fuente: catfact.ninja/fact',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                CatFactStatus.loaded || CatFactStatus.failure => Semantics(
                    key: const ValueKey('fact-error'),
                    liveRegion: true,
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.wifi_off_rounded,
                                size: 18,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                status == CatFactStatus.failure
                                    ? (errorMessage ??
                                        'No pudimos obtener un dato curioso en este momento.')
                                    : 'No hay un dato curioso disponible en este momento.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar dato curioso'),
                        ),
                      ],
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
