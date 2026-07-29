import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

class ListingSuggestionValidator {
  const ListingSuggestionValidator({
    this.draftValidator = const ListingDraftValidator(),
  });

  final ListingDraftValidator draftValidator;

  bool isValid(ListingSuggestion suggestion) {
    return draftValidator.titleError(suggestion.title) == null;
  }

  void validateOrThrow(ListingSuggestion suggestion) {
    if (!isValid(suggestion)) {
      throw const InvalidListingSuggestionException();
    }
  }
}
