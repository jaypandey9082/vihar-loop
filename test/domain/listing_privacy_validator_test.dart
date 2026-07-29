import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/domain/listing_privacy_validator.dart';

void main() {
  const validator = ListingPrivacyValidator();

  group('ListingPrivacyValidator direct contact', () {
    for (final value in [
      '+91 98765 43210',
      '98765-43210',
      '(98765) 43210',
      'person@example.com',
      'https://example.com/contact',
      'http://example.com',
      'www.example.com',
      '@sample_handle',
      'sample@upi',
    ]) {
      test('rejects $value', () {
        expect(
          validator.firstIssue(value),
          ListingPrivacyIssue.directContact,
        );
      });
    }
  });

  group('ListingPrivacyValidator precise location', () {
    for (final value in [
      'Flat 302',
      'Flat no. 302',
      'Room 17',
      'Room no 17',
      'House No. 45',
      'Shop 12',
      'Unit B-4',
      'Door 7',
      'Wing B',
      'B Wing',
      'Block A',
      'Tower 3',
      '3rd floor',
      'Floor 4',
      '12 Station Road',
      '7 MG Road',
      'Lane No. 4',
      'PIN 400999',
      'Pincode: 400999',
      'Postal code 400999',
      '19.0760, 72.8777',
      'latitude 19.0760 longitude 72.8777',
      'Building name: Example Residency',
      'Society no. 8',
    ]) {
      test('rejects $value', () {
        expect(
          validator.firstIssue(value),
          ListingPrivacyIssue.preciseLocation,
        );
      });
    }
  });

  group('ListingPrivacyValidator ordinary content', () {
    for (final value in [
      'Class 12 statistics notes',
      'USB-C 65W charger',
      'Need this for two hours',
      'Room heater available',
      'Building a Flutter app',
      'Road bicycle',
      'Street photography book',
      'Wing Chun practice',
      'Block chain notes',
      'Pin board',
      'Coordinate geometry notes',
      'Near Vidyavihar station',
      'Somaiya side',
      'Near the library',
      'On campus',
      'Meet at a public place',
      'कक्षा की किताबें उपलब्ध हैं',
      'मराठी अभ्यासाच्या नोट्स उपलब्ध आहेत',
      'A friend’s well-kept calculator',
    ]) {
      test('allows $value', () {
        expect(validator.firstIssue(value), isNull);
      });
    }

    test('allows a valid 500-character Unicode description', () {
      final value = List.filled(100, 'नोट्स ').join().substring(0, 500);
      expect(value, hasLength(500));
      expect(validator.firstIssue(value), isNull);
    });

    test('ignores out-of-range coordinate-like values and versions', () {
      expect(validator.firstIssue('version 19.0760, 272.8777'), isNull);
      expect(validator.firstIssue('dimensions 19.07, 72.87'), isNull);
    });
  });

  group('ListingDraftValidator privacy integration', () {
    const draftValidator = ListingDraftValidator();
    final now = DateTime(2026, 7, 30, 12);

    ListingDraft draft({
      String title = 'Useful calculator available',
      String description =
          'A working calculator is available near Vidyavihar station.',
    }) {
      return ListingDraft(
        kind: ListingKind.offer,
        title: title,
        description: description,
        category: ListingCategory.booksAndStudy,
        approximateArea: ApproximateArea.somaiyaSide,
        contactPreference: ContactPreference.publicPlace,
        activeUntil: now.add(const Duration(hours: 2)),
      );
    }

    test('uses distinct title and description privacy errors', () {
      expect(
        draftValidator.titleError('Reach me at @sample_handle'),
        ListingDraftValidator.directContactError,
      );
      expect(
        draftValidator.descriptionError(
          'Please collect this from Flat 302 after class.',
        ),
        ListingDraftValidator.preciseLocationError,
      );
    });

    test('preserves structural validation priority', () {
      expect(
        draftValidator.titleError('@x'),
        'Use at least 5 characters.',
      );
      expect(
        draftValidator.descriptionError('Flat 1'),
        'Add a little more detail so people know what to expect.',
      );
    });

    test('generic exception contains no rejected draft content', () {
      const rejected = 'person@example.com';
      try {
        draftValidator.validateOrThrow(
          draft(description: 'Contact $rejected for this useful item.'),
          now,
        );
        fail('Expected privacy validation to reject the draft.');
      } on InvalidListingDraftException catch (error) {
        expect(error.toString(), isNot(contains(rejected)));
        expect(error.toString(), 'The listing draft is invalid.');
      }
    });

    test('repository-facing validation accepts broad Unicode content', () {
      expect(
        draftValidator.isValid(
          draft(
            title: 'मराठी अभ्यासाच्या नोट्स',
            description:
                'या नोट्स विद्याविहार स्टेशनजवळ सार्वजनिक ठिकाणी मिळतील.',
          ),
          now,
        ),
        isTrue,
      );
    });
  });
}
