import 'dart:async';

sealed class BreedsEvent {
  const BreedsEvent();
}

/// Initial directory load implementing Stale-While-Revalidate (SWR).
final class BreedsStarted extends BreedsEvent {
  const BreedsStarted();
}

/// Pull-to-refresh action that reloads page 1 and preserves local cache on failure.
final class BreedsRefreshed extends BreedsEvent {
  const BreedsRefreshed({this.completer});

  final Completer<void>? completer;
}

/// Infinite scroll trigger requesting the next page with concurrency control.
final class BreedsNextPageRequested extends BreedsEvent {
  const BreedsNextPageRequested();
}

/// Local in-memory search query update (debounced unless [immediate] is true).
final class BreedsSearchQueryChanged extends BreedsEvent {
  const BreedsSearchQueryChanged(this.query, {this.immediate = false});

  final String query;
  final bool immediate;
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
