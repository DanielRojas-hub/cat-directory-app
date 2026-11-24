import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../bloc/breeds_bloc.dart';
import '../bloc/breeds_event.dart';
import '../bloc/breeds_state.dart';
import '../widgets/breed_card.dart';
import '../widgets/connectivity_status_banner.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/shimmer_box.dart';

/// Main interactive directory displaying paginated cat breeds with debounced
/// local search, pull-to-refresh, offline SWR cues and infinite scroll.
class BreedsListPage extends StatefulWidget {
  const BreedsListPage({super.key});

  @override
  State<BreedsListPage> createState() => _BreedsListPageState();
}

class _BreedsListPageState extends State<BreedsListPage> {
  static const double _prefetchThresholdPx = 280;

  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _prefetchThresholdPx) {
      context.read<BreedsBloc>().add(const BreedsNextPageRequested());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showNoticeSnackBar(BuildContext context, BreedsNotice notice) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, backgroundColor, foregroundColor) = switch (notice.kind) {
      BreedsNoticeKind.info => (
          Icons.wifi_rounded,
          colorScheme.inverseSurface,
          colorScheme.onInverseSurface,
        ),
      BreedsNoticeKind.warning => (
          Icons.info_outline_rounded,
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      BreedsNoticeKind.error => (
          Icons.error_outline_rounded,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notice.message,
                  style: TextStyle(color: foregroundColor),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<BreedsBloc>();
    bloc.add(const BreedsRefreshed());
    // Wait until revalidation completes or notice is emitted so RefreshIndicator closes smoothly.
    await bloc.stream.firstWhere(
      (s) => !s.isRevalidating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<BreedsBloc, BreedsState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice?.id != current.notice?.id,
      listener: (context, state) {
        final notice = state.notice;
        if (notice != null) {
          _showNoticeSnackBar(context, notice);
          context.read<BreedsBloc>().add(const BreedsNoticeCleared());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_rounded, size: 22),
              SizedBox(width: 8),
              Text(
                'Cat Directory',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            BlocBuilder<BreedsBloc, BreedsState>(
              buildWhen: (prev, curr) =>
                  prev.breeds.length != curr.breeds.length ||
                  prev.total != curr.total ||
                  prev.isOnline != curr.isOnline,
              builder: (context, state) {
                if (state.breeds.isEmpty) {
                  return const SizedBox.shrink();
                }
                final countLabel = state.total > 0
                    ? '${state.breeds.length}/${state.total}'
                    : '${state.breeds.length}';
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: state.isOnline
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    label: Text(
                      countLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: state.isOnline
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  return TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (query) => context
                        .read<BreedsBloc>()
                        .add(BreedsSearchQueryChanged(query)),
                    decoration: InputDecoration(
                      hintText: 'Buscar raza (ej. Abyssinian)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<BreedsBloc>()
                                    .add(const BreedsSearchQueryChanged(''));
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<BreedsBloc, BreedsState>(
              buildWhen: (prev, curr) =>
                  prev.isOnline != curr.isOnline ||
                  prev.isFromCache != curr.isFromCache ||
                  prev.isRevalidating != curr.isRevalidating ||
                  prev.lastSyncedAt != curr.lastSyncedAt,
              builder: (context, state) {
                return ConnectivityStatusBanner(
                  isOnline: state.isOnline,
                  isFromCache: state.isFromCache,
                  isRevalidating: state.isRevalidating,
                  lastSyncedAt: state.lastSyncedAt,
                  onRetry: () =>
                      context.read<BreedsBloc>().add(const BreedsRefreshed()),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<BreedsBloc, BreedsState>(
                builder: (context, state) {
                  if (state.status == BreedsStatus.initial ||
                      (state.status == BreedsStatus.loading &&
                          state.breeds.isEmpty)) {
                    return const BreedsSkeletonList();
                  }

                  if (state.status == BreedsStatus.failure &&
                      state.breeds.isEmpty) {
                    return _InitialErrorView(
                      message: state.errorMessage ??
                          'No pudimos cargar el directorio de razas.',
                      isOnline: state.isOnline,
                      onRetry: () =>
                          context.read<BreedsBloc>().add(const BreedsStarted()),
                    );
                  }

                  final visibleBreeds = state.filteredBreeds;

                  if (visibleBreeds.isEmpty && state.isSearching) {
                    return _EmptySearchView(
                      query: state.searchQuery.trim(),
                      loadedCount: state.breeds.length,
                      hasMore: state.hasMore,
                      onClear: () {
                        _searchController.clear();
                        context
                            .read<BreedsBloc>()
                            .add(const BreedsSearchQueryChanged(''));
                      },
                      onLoadMore: () => context
                          .read<BreedsBloc>()
                          .add(const BreedsNextPageRequested()),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          sliver: SliverList.separated(
                            itemCount: visibleBreeds.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final breed = visibleBreeds[index];
                              return BreedCard(
                                breed: breed,
                                onTap: () => context.push(
                                  AppRoutes.breedDetailPath(breed.breed),
                                  extra: breed,
                                ),
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: PaginationFooter(
                            isLoadingMore: state.isLoadingMore,
                            hasMore: state.hasMore,
                            isSearching: state.isSearching,
                            loadedCount: state.breeds.length,
                            totalCount: state.total,
                            errorMessage: state.paginationErrorMessage,
                            onRetry: () => context
                                .read<BreedsBloc>()
                                .add(const BreedsNextPageRequested()),
                            onLoadMore: () => context
                                .read<BreedsBloc>()
                                .add(const BreedsNextPageRequested()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialErrorView extends StatelessWidget {
  const _InitialErrorView({
    required this.message,
    required this.isOnline,
    required this.onRetry,
  });

  final String message;
  final bool isOnline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnline ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
                size: 44,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isOnline
                  ? 'No pudimos conectar con el directorio'
                  : 'Estás sin conexión a internet',
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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView({
    required this.query,
    required this.loadedCount,
    required this.hasMore,
    required this.onClear,
    required this.onLoadMore,
  });

  final String query;
  final int loadedCount;
  final bool hasMore;
  final VoidCallback onClear;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin coincidencias para "$query"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Buscamos entre las $loadedCount razas cargadas actualmente en memoria.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Limpiar filtro'),
                ),
                if (hasMore)
                  OutlinedButton.icon(
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Cargar más razas'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
