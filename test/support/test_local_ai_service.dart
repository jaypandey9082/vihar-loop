import 'dart:async';

import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

class SuggestionRequest {
  const SuggestionRequest({
    required this.description,
    required this.preferredKind,
  });

  final String description;
  final ListingKind preferredKind;
}

class TestLocalAiService implements LocalAiService {
  TestLocalAiService({
    ListingSuggestion? result,
    this.failure,
    this.pending,
  }) : result = result ??
            const ListingSuggestion(
              kind: ListingKind.need,
              title: 'Guitar capo for rehearsal',
              category: ListingCategory.musicHobbiesAndSports,
              source: ListingSuggestionSource.deterministicFallback,
            );

  ListingSuggestion result;
  Object? failure;
  Completer<ListingSuggestion>? pending;
  final requests = <SuggestionRequest>[];

  @override
  Future<ListingSuggestion> suggestListing({
    required String description,
    required ListingKind preferredKind,
  }) async {
    requests.add(
      SuggestionRequest(
        description: description,
        preferredKind: preferredKind,
      ),
    );
    if (failure case final error?) {
      throw error;
    }
    if (pending case final completer?) {
      return completer.future;
    }
    return result;
  }
}
