import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/breeds/domain/entities/breed.dart';
import '../../features/breeds/presentation/bloc/breed_detail_cubit.dart';
import '../../features/breeds/presentation/pages/breed_detail_page.dart';
import '../../features/breeds/presentation/pages/breeds_list_page.dart';
import '../di/injection.dart';

/// Centralized route definitions and builders for the application.
abstract final class AppRoutes {
  static const String home = '/';
  static const String breedDetail = '/breed/:name';

  /// Builds the parameterized path for a specific breed name.
  static String breedDetailPath(String breedName) {
    return '/breed/${Uri.encodeComponent(breedName)}';
  }
}

/// Creates the application [GoRouter] with parameterized detail routing
/// and deep-link URI normalization.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  BreedDetailCubit Function()? detailCubitFactory,
}) {
  final createDetailCubit = detailCubitFactory ?? () => sl<BreedDetailCubit>();

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      // Support custom-scheme links like `catdirectory://breed/Abyssinian`.
      if (state.uri.scheme == 'catdirectory' && state.uri.host == 'breed') {
        final rawSlug = state.uri.path.replaceFirst(RegExp(r'^/+'), '');
        if (rawSlug.isNotEmpty) {
          return '/breed/$rawSlug';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const BreedsListPage(),
      ),
      GoRoute(
        path: AppRoutes.breedDetail,
        name: 'breedDetail',
        builder: (context, state) {
          final breedName = state.pathParameters['name'] ?? '';
          final extraBreed = state.extra is Breed ? state.extra! as Breed : null;

          return BlocProvider<BreedDetailCubit>(
            key: ValueKey(breedName),
            create: (_) => createDetailCubit()
              ..load(
                breedName: breedName,
                initialBreed: extraBreed,
              ),
            child: BreedDetailPage(breedName: breedName),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => _RouteNotFoundPage(
      attemptedUri: state.uri.toString(),
    ),
  );
}

class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage({required this.attemptedUri});

  final String attemptedUri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta no encontrada')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore_off_outlined,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No encontramos la página solicitada',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          attemptedUri,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Volver al directorio'),
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
    );
  }
}
