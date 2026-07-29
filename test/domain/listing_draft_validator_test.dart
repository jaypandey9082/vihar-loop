import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';

void main() {
  const validator = ListingDraftValidator();
  final now = DateTime(2026, 7, 30, 12);

  ListingDraft draft({
    String title = 'Music stand needed',
    String description = 'A foldable stand would help with rehearsal.',
    DateTime? activeUntil,
  }) {
    return ListingDraft(
      kind: ListingKind.need,
      title: title,
      description: description,
      category: ListingCategory.musicHobbiesAndSports,
      approximateArea: ApproximateArea.somaiyaSide,
      contactPreference: ContactPreference.publicPlace,
      activeUntil: activeUntil ?? now.add(const Duration(hours: 2)),
    );
  }

  test('normalization trims edges and preserves content and typed fields', () {
    final original = draft(
      title: '  Music stand needed  ',
      description: '  First paragraph.\n\nSecond paragraph.  ',
    );
    final normalized = original.normalized();

    expect(normalized.title, 'Music stand needed');
    expect(normalized.description, 'First paragraph.\n\nSecond paragraph.');
    expect(normalized.kind, original.kind);
    expect(normalized.category, original.category);
    expect(normalized.approximateArea, original.approximateArea);
    expect(normalized.contactPreference, original.contactPreference);
    expect(normalized.activeUntil, original.activeUntil);
  });

  group('title', () {
    test('enforces required and length boundaries', () {
      expect(validator.titleError(null), 'Add a short title.');
      expect(validator.titleError('   '), 'Add a short title.');
      expect(validator.titleError('four'), 'Use at least 5 characters.');
      expect(validator.titleError('fives'), isNull);
      expect(validator.titleError('a' * 80), isNull);
      expect(
        validator.titleError('a' * 81),
        'Keep the title under 80 characters.',
      );
    });

    test('rejects newline and obvious contact details', () {
      expect(validator.titleError('Valid\nsecond line'), isNotNull);
      expect(validator.titleError('Write to user@example.test'), isNotNull);
      expect(validator.titleError('See https://example.test'), isNotNull);
      expect(validator.titleError('Call +91 98765-43210'), isNotNull);
    });

    test('allows ordinary non-contact numbers', () {
      expect(validator.titleError('Needed for two hours'), isNull);
      expect(validator.titleError('Class 12 notes'), isNull);
    });
  });

  group('description', () {
    test('enforces required and length boundaries', () {
      expect(validator.descriptionError(null), isNotNull);
      expect(validator.descriptionError('too short'), isNotNull);
      expect(validator.descriptionError('a' * 15), isNull);
      expect(validator.descriptionError('a' * 500), isNull);
      expect(validator.descriptionError('a' * 501), isNotNull);
    });

    test('rejects contact details but accepts Unicode and punctuation', () {
      expect(
        validator.descriptionError('Please email user@example.test today.'),
        isNotNull,
      );
      expect(
        validator.descriptionError('Details at www.example.test/listing'),
        isNotNull,
      );
      expect(
        validator.descriptionError('Please call 98765 43210 after class.'),
        isNotNull,
      );
      expect(
        validator.descriptionError(
          'Rehearsal notes—परीक्षण, punctuation, and Unicode ✓.',
        ),
        isNull,
      );
    });
  });

  group('deadline', () {
    test('enforces the 15-minute and seven-day inclusive boundaries', () {
      expect(validator.activeUntilError(null, now), isNotNull);
      expect(validator.activeUntilError(now, now), isNotNull);
      expect(
        validator.activeUntilError(
          now.add(const Duration(minutes: 14, seconds: 59)),
          now,
        ),
        isNotNull,
      );
      expect(
        validator.activeUntilError(now.add(const Duration(minutes: 15)), now),
        isNull,
      );
      expect(
        validator.activeUntilError(now.add(const Duration(days: 7)), now),
        isNull,
      );
      expect(
        validator.activeUntilError(
          now.add(const Duration(days: 7, microseconds: 1)),
          now,
        ),
        isNotNull,
      );
    });

    test('uses the supplied local DateTime deterministically', () {
      final nearMidnight = DateTime(2026, 7, 30, 23, 55);
      expect(
        validator.activeUntilError(
          DateTime(2026, 7, 31, 0, 10),
          nearMidnight,
        ),
        isNull,
      );
    });
  });

  test('repository validation throws a safe exception without draft data', () {
    const privateTitle = 'user@example.test';
    const privateDescription = 'Call +91 98765-43210 for this item.';
    final invalid = draft(
      title: privateTitle,
      description: privateDescription,
    );

    expect(
      () => validator.validateOrThrow(invalid, now),
      throwsA(
        isA<InvalidListingDraftException>().having(
          (error) => error.toString(),
          'safe text',
          allOf(
            isNot(contains(privateTitle)),
            isNot(contains(privateDescription)),
            isNot(contains('98765')),
          ),
        ),
      ),
    );
  });
}
