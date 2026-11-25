import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/breed.dart';
import '../../domain/entities/cat_fact.dart';
import '../bloc/breed_detail_cubit.dart';
import '../bloc/breed_detail_state.dart';
import '../widgets/breed_avatar.dart';
import '../widgets/cat_fact_card.dart';

/// Parameterized breed detail view (`/breed/:name`) showing all breed attributes
/// and an independently loaded random cat fact from `/fact`.
class BreedDetailPage extends StatelessWidget {
  const BreedDetailPage({
    super.key,
    required this.breedName,
  });

  final String breedName;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver al directorio',
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: BlocSelector<BreedDetailCubit, BreedDetailState, String>(
            selector: (state) {
              final resolved = state.breed?.breed.trim();
              return (resolved != null && resolved.isNotEmpty)
                  ? resolved
                  : breedName;
            },
            builder: (context, resolvedTitle) {
              return Text(
                resolvedTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocBuilder<BreedDetailCubit, BreedDetailState>(
            builder: (context, state) {
              return switch (state.breedStatus) {
                BreedDetailStatus.initial || BreedDetailStatus.loading =>
                  Semantics(
                    liveRegion: true,
                    label: 'Cargando detalles de la raza $breedName',
                    excludeSemantics: true,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Cargando detalles de la raza...',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                BreedDetailStatus.failure => _BreedLookupErrorView(
                    breedName: breedName,
                    message: state.breedErrorMessage ??
                        'No encontramos los detalles de esta raza.',
                    onRetry: () => context
                        .read<BreedDetailCubit>()
                        .retryBreedLookup(breedName),
                    onGoHome: () => context.go(AppRoutes.home),
                  ),
                BreedDetailStatus.loaded => _BreedDetailContent(
                    breed: state.breed!,
                    factStatus: state.factStatus,
                    fact: state.fact,
                    factErrorMessage: state.factErrorMessage,
                    onRefreshFact: () =>
                        context.read<BreedDetailCubit>().loadRandomFact(),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _BreedDetailContent extends StatelessWidget {
  const _BreedDetailContent({
    required this.breed,
    required this.factStatus,
    required this.fact,
    required this.factErrorMessage,
    required this.onRefreshFact,
  });

  final Breed breed;
  final CatFactStatus factStatus;
  final CatFact? fact;
  final String? factErrorMessage;
  final VoidCallback onRefreshFact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  BreedAvatar(breed: breed, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          breed.breed,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                breed.displayCountry,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              'Ficha de la Raza',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AttributeTile(
            icon: Icons.pets_rounded,
            label: 'Raza (Breed)',
            value: breed.breed,
          ),
          const SizedBox(height: 8),
          _AttributeTile(
            icon: Icons.flag_outlined,
            label: 'País (Country)',
            value: breed.displayCountry,
          ),
          const SizedBox(height: 8),
          _AttributeTile(
            icon: Icons.history_edu_rounded,
            label: 'Origen (Origin)',
            value: breed.displayOrigin,
          ),
          const SizedBox(height: 8),
          _AttributeTile(
            icon: Icons.spa_outlined,
            label: 'Pelaje (Coat)',
            value: breed.displayCoat,
          ),
          const SizedBox(height: 8),
          _AttributeTile(
            icon: Icons.palette_outlined,
            label: 'Patrón (Pattern)',
            value: breed.displayPattern,
          ),
          const SizedBox(height: 22),
          CatFactCard(
            status: factStatus,
            fact: fact,
            errorMessage: factErrorMessage,
            onRefresh: onRefreshFact,
          ),
        ],
      ),
    );
  }
}

class _AttributeTile extends StatelessWidget {
  const _AttributeTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreedLookupErrorView extends StatelessWidget {
  const _BreedLookupErrorView({
    required this.breedName,
    required this.message,
    required this.onRetry,
    required this.onGoHome,
  });

  final String breedName;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 54,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pudimos cargar "$breedName"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGoHome,
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Ir al directorio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
