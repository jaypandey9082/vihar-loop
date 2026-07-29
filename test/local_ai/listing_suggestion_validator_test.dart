import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/listing_suggestion_validator.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

void main() {
  const validator = ListingSuggestionValidator();

  ListingSuggestion suggestion(
    String title, {
    ListingKind kind = ListingKind.need,
    ListingCategory category = ListingCategory.other,
  }) {
    return ListingSuggestion(
      kind: kind,
      title: title,
      category: category,
      source: ListingSuggestionSource.deterministicFallback,
    );
  }

  test('accepts both kinds and Other through the shared title validator', () {
    expect(
      validator.isValid(
        suggestion(
          'Something useful nearby',
          kind: ListingKind.need,
          category: ListingCategory.other,
        ),
      ),
      isTrue,
    );
    expect(
      validator.isValid(
        suggestion(
          'Statistics notes',
          kind: ListingKind.offer,
          category: ListingCategory.booksAndStudy,
        ),
      ),
      isTrue,
    );
    expect(
      validator.draftValidator,
      isA<ListingDraftValidator>(),
    );
  });

  final invalidTitles = <String, String>{
    'empty': '',
    'four characters': 'Four',
    'eighty-one characters': List.filled(81, 'a').join(),
    'multiple lines': 'Useful title\nsecond line',
    'phone number': '+91 98765 43210',
    'email': 'person@example.com',
    'URL': 'https://example.com/item',
    'social handle': 'Message @nearby_person',
    'payment ID': 'Pay name@upi',
    'flat number': 'Collect from Flat 302',
    'PIN code': 'Pickup near PIN 400999',
    'coordinates': 'Meet at 19.0760, 72.8777',
  };

  for (final entry in invalidTitles.entries) {
    test('rejects ${entry.key} without echoing the title', () {
      final value = suggestion(entry.value);
      expect(validator.isValid(value), isFalse);
      final matcher = isA<InvalidListingSuggestionException>().having(
        (error) => error.toString(),
        'message',
        entry.value.isEmpty
            ? equals('The listing suggestion is invalid.')
            : isNot(contains(entry.value)),
      );
      expect(() => validator.validateOrThrow(value), throwsA(matcher));
    });
  }
}
