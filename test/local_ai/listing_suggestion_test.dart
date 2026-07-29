import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';

void main() {
  test('preserves the complete transient suggestion contract', () {
    const suggestion = ListingSuggestion(
      kind: ListingKind.offer,
      title: 'Statistics notes',
      category: ListingCategory.booksAndStudy,
      source: ListingSuggestionSource.deterministicFallback,
    );

    expect(suggestion.kind, ListingKind.offer);
    expect(suggestion.title, 'Statistics notes');
    expect(suggestion.category, ListingCategory.booksAndStudy);
    expect(
      suggestion.source,
      ListingSuggestionSource.deterministicFallback,
    );
  });

  test('source labels are explicit and user-facing', () {
    expect(
      ListingSuggestionSource.deterministicFallback.label,
      'Built-in offline rules',
    );
    expect(
      ListingSuggestionSource.onDeviceModel.label,
      'On-device model',
    );
  });

  test('contains no persistence or protected listing fields', () {
    const fields = <String>{'kind', 'title', 'category', 'source'};
    expect(fields, isNot(contains('description')));
    expect(fields, isNot(contains('approximateArea')));
    expect(fields, isNot(contains('contactPreference')));
    expect(fields, isNot(contains('activeUntil')));
    expect(fields, isNot(contains('id')));
  });
}
