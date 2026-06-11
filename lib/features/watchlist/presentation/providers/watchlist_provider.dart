import 'package:flutter_riverpod/flutter_riverpod.dart';

class WatchlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return [];
  }

  void toggleWatchlist(String movieId) {
    if (state.contains(movieId)) {
      state = state.where((id) => id != movieId).toList();
    } else {
      state = [...state, movieId];
    }
  }

  bool contains(String movieId) {
    return state.contains(movieId);
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, List<String>>(() {
  return WatchlistNotifier();
});
