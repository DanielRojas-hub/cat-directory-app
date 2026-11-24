sealed class BreedsEvent {
  const BreedsEvent();
}

/// Initial directory load implementing Stale-While-Revalidate (SWR).
final class BreedsStarted extends BreedsEvent {
  const BreedsStarted();
}

/// Pull-to-refresh action that invalidates local cache and reloads from page 1.
final class BreedsRefreshed extends BreedsEvent {
  const BreedsRefreshed();
}

/// Infinite scroll trigger requesting the next page with concurrency control.
final class BreedsNextPageRequested extends BreedsEvent {
  const BreedsNextPageRequested();
}

/// Local in-memory search query update (debounced).
final class BreedsSearchQueryChanged extends BreedsEvent {
  const BreedsSearchQueryChanged(this.query);

  final String query;
}

/// Emitted when device network connectivity transitions online/offline.
final class BreedsConnectivityChanged extends BreedsEvent {
  const BreedsConnectivityChanged({required this.isOnline});

  final bool isOnline;
}

/// Emitted when the app returns to foreground after being backgrounded.
final class BreedsAppResumed extends BreedsEvent {
  const BreedsAppResumed({required this.backgroundDuration});

  final Duration backgroundDuration;
}

/// Clears a transient snackbar notice once rendered by the UI.
final class BreedsNoticeCleared extends BreedsEvent {
  const BreedsNoticeCleared();
}
