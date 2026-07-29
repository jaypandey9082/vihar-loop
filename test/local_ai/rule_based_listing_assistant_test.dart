import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/listing_suggestion_validator.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';

void main() {
  const assistant = RuleBasedListingAssistant();
  const suggestionValidator = ListingSuggestionValidator();

  final cases = <({
    String description,
    ListingKind preferred,
    ListingKind kind,
    ListingCategory category,
    String title,
  })>[
    (
      description: 'Need a guitar capo for rehearsal near Somaiya today.',
      preferred: ListingKind.need,
      kind: ListingKind.need,
      category: ListingCategory.musicHobbiesAndSports,
      title: 'Guitar capo for rehearsal',
    ),
    (
      description: 'Offering my statistics notes until tomorrow.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.booksAndStudy,
      title: 'Statistics notes',
    ),
    (
      description: 'Looking for a USB-C charger for two hours.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.electronics,
      title: 'USB-C charger',
    ),
    (
      description: 'Can help set up Flutter this evening.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.skillsAndServices,
      title: 'Set up Flutter',
    ),
    (
      description: 'Need help repairing a laptop.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.skillsAndServices,
      title: 'Help repairing a laptop',
    ),
    (
      description: 'Spare umbrella available tonight.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.homeAndTools,
      title: 'Spare umbrella available',
    ),
    (
      description: 'Need badminton shuttles near the station.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.musicHobbiesAndSports,
      title: 'Badminton shuttles near the station',
    ),
    (
      description: 'Giving away entrance exam books.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.booksAndStudy,
      title: 'Entrance exam books',
    ),
    (
      description: 'Need a basic screwdriver set.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.homeAndTools,
      title: 'Basic screwdriver set',
    ),
    (
      description: 'Offering homemade tiffin tonight.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.foodAndEssentials,
      title: 'Homemade tiffin',
    ),
    (
      description: 'Looking for something useful nearby.',
      preferred: ListingKind.need,
      kind: ListingKind.need,
      category: ListingCategory.other,
      title: 'Something useful nearby',
    ),
    (
      description: 'Can lend a power bank.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.electronics,
      title: 'Power bank',
    ),
    (
      description: 'Musical keyboard needed for rehearsal.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.musicHobbiesAndSports,
      title: 'Musical keyboard needed for rehearsal',
    ),
    (
      description: 'USB keyboard needed for my laptop.',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.electronics,
      title: 'USB keyboard needed for my laptop',
    ),
    (
      description: 'Room heater available for tonight.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.homeAndTools,
      title: 'Room heater available',
    ),
    (
      description: 'Building a Flutter app and can help someone set it up.',
      preferred: ListingKind.need,
      kind: ListingKind.offer,
      category: ListingCategory.skillsAndServices,
      title: 'Building a Flutter app and can help someone set it up',
    ),
    (
      description: 'मुझे आज गिटार कैपो चाहिए',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.musicHobbiesAndSports,
      title: 'मुझे आज गिटार कैपो चाहिए',
    ),
    (
      description: 'अभ्यासासाठी नोट्स पाहिजेत',
      preferred: ListingKind.offer,
      kind: ListingKind.need,
      category: ListingCategory.booksAndStudy,
      title: 'अभ्यासासाठी नोट्स पाहिजेत',
    ),
  ];

  for (var index = 0; index < cases.length; index++) {
    final value = cases[index];
    test('evaluation case ${index + 1}', () async {
      final original = value.description;
      final result = await assistant.suggestListing(
        description: value.description,
        preferredKind: value.preferred,
      );

      expect(result.kind, value.kind);
      expect(result.category, value.category);
      expect(result.title, value.title);
      expect(
        result.source,
        ListingSuggestionSource.deterministicFallback,
      );
      expect(suggestionValidator.isValid(result), isTrue);
      expect(value.description, original);
    });
  }

  test('no signal and equal need/offer scores use preferred kind', () async {
    final noSignal = await assistant.suggestListing(
      description: 'Something useful is nearby for a short while.',
      preferredKind: ListingKind.offer,
    );
    expect(noSignal.kind, ListingKind.offer);
    expect(noSignal.category, ListingCategory.other);

    final equal = await assistant.suggestListing(
      description: 'Need and offering one useful item nearby.',
      preferredKind: ListingKind.offer,
    );
    expect(equal.kind, ListingKind.offer);
  });

  test('repeated signals remain stable and input is deterministic', () async {
    const description =
        'Need need need a guitar capo for rehearsal near Somaiya today.';
    final results = <ListingSuggestion>[];
    for (var index = 0; index < 10; index++) {
      results.add(
        await assistant.suggestListing(
          description: description,
          preferredKind: ListingKind.offer,
        ),
      );
    }
    final first = results.first;
    for (final result in results.skip(1)) {
      expect(result.kind, first.kind);
      expect(result.title, first.title);
      expect(result.category, first.category);
      expect(result.source, first.source);
    }
  });

  test('normal Unicode is retained safely', () async {
    final result = await assistant.suggestListing(
      description: 'Need café-style संगीत notes for rehearsal.',
      preferredKind: ListingKind.need,
    );
    expect(result.title.toLowerCase(), contains('café'));
    expect(result.title, contains('संगीत'));
    expect(suggestionValidator.isValid(result), isTrue);
  });

  final invalidDescriptions = <String, String>{
    'empty': '',
    'whitespace': '   ',
    'short': 'Too short',
    'over 500': List.filled(501, 'a').join(),
    'email': 'Need notes from person@example.com today.',
    'phone': 'Need a charger, call +91 98765 43210.',
    'URL': 'Need notes from https://example.com today.',
    'social handle': 'Need a charger from @nearby_person today.',
    'payment ID': 'Offering lunch, pay name@upi afterward.',
    'flat': 'Collect the heater from Flat 302, Wing B.',
    'room': 'Need notes delivered to Room 21 today.',
    'floor': 'Offering books from the 4th floor today.',
    'street': 'Need a charger at 14 MG Road today.',
    'PIN': 'Need an umbrella near PIN 400999 today.',
    'coordinates': 'Need help around 19.0760, 72.8777 today.',
  };

  for (final entry in invalidDescriptions.entries) {
    test('rejects invalid ${entry.key} before producing output', () async {
      final messageMatcher = entry.value.isEmpty
          ? equals('The Draft Assist input is invalid.')
          : isNot(contains(entry.value));
      await expectLater(
        assistant.suggestListing(
          description: entry.value,
          preferredKind: ListingKind.need,
        ),
        throwsA(
          isA<InvalidLocalAiInputException>().having(
            (error) => error.toString(),
            'message',
            messageMatcher,
          ),
        ),
      );
    });
  }
}
