import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/place_suggestion_draft_store.dart';
import '../../data/place_suggestion_repository.dart';
import '../../domain/models/place_suggestion_model.dart';

/// PlaceSuggestionRepository provider
final placeSuggestionRepositoryProvider = Provider<PlaceSuggestionRepository>(
  (ref) => PlaceSuggestionRepository(),
);

final placeSuggestionDraftStoreProvider = Provider<PlaceSuggestionDraftStore>(
  (ref) => PlaceSuggestionDraftStore(),
);

/// Bekleyen öneri sayısı stream'i (admin badge için)
final pendingSuggestionCountProvider = StreamProvider<int>((ref) {
  return ref
      .read(placeSuggestionRepositoryProvider)
      .pendingSuggestionCountStream();
});

/// Duruma göre önerileri getiren FutureProvider ailesi
final suggestionsProvider =
    FutureProvider.family<List<PlaceSuggestionModel>, SuggestionStatus?>((
      ref,
      status,
    ) async {
      return ref
          .read(placeSuggestionRepositoryProvider)
          .getSuggestions(status: status);
    });
