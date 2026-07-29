import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';

abstract interface class LocalAiService {
  Future<ListingSuggestion> suggestListing({
    required String description,
    required ListingKind preferredKind,
  });
}

class InvalidLocalAiInputException implements Exception {
  const InvalidLocalAiInputException();

  @override
  String toString() => 'The Draft Assist input is invalid.';
}

class InvalidListingSuggestionException implements Exception {
  const InvalidListingSuggestionException();

  @override
  String toString() => 'The listing suggestion is invalid.';
}
