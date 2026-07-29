import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';

void main() {
  group('Listing.copyWith', () {
    final original = Listing(
      id: 'local-listing',
      neighborhoodId: 'vidyavihar',
      kind: ListingKind.offer,
      title: 'Test title',
      description: 'Test description',
      category: ListingCategory.homeAndTools,
      approximateArea: ApproximateArea.vidyaviharStationWest,
      contactPreference: ContactPreference.mutualConsent,
      createdAt: DateTime(2026, 7, 30, 9),
      activeUntil: DateTime(2026, 7, 31, 18),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.local,
    );

    test('changes one field while preserving every other field', () {
      final updated = original.copyWith(isSaved: true);

      expect(updated.isSaved, isTrue);
      expect(updated.isContacted, original.isContacted);
      expect(updated.status, original.status);
      expect(updated.id, original.id);
      expect(updated.neighborhoodId, original.neighborhoodId);
      expect(updated.kind, original.kind);
      expect(updated.title, original.title);
      expect(updated.description, original.description);
      expect(updated.category, original.category);
      expect(updated.approximateArea, original.approximateArea);
      expect(updated.contactPreference, original.contactPreference);
      expect(updated.createdAt, original.createdAt);
      expect(updated.activeUntil, original.activeUntil);
      expect(updated.origin, original.origin);
    });

    test('changes multiple mutable fields without changing the original', () {
      final updated = original.copyWith(
        isSaved: true,
        isContacted: true,
        status: ListingStatus.closed,
      );

      expect(updated.isSaved, isTrue);
      expect(updated.isContacted, isTrue);
      expect(updated.status, ListingStatus.closed);
      expect(original.isSaved, isFalse);
      expect(original.isContacted, isFalse);
      expect(original.status, ListingStatus.open);
      expect(identical(updated, original), isFalse);
    });

    test('can change contacted and status independently', () {
      expect(original.copyWith(isContacted: true).isContacted, isTrue);
      expect(
        original.copyWith(status: ListingStatus.closed).status,
        ListingStatus.closed,
      );
    });
  });

  group('Listing labels', () {
    test('kind labels and time wording are user-facing', () {
      expect(ListingKind.need.label, 'Need');
      expect(ListingKind.need.activeUntilLabel, 'Needed by');
      expect(ListingKind.offer.label, 'Offer');
      expect(ListingKind.offer.activeUntilLabel, 'Available until');
    });

    test('category labels do not expose enum names', () {
      expect(
        {
          for (final category in ListingCategory.values)
            category: category.label,
        },
        {
          ListingCategory.booksAndStudy: 'Books & study',
          ListingCategory.electronics: 'Electronics',
          ListingCategory.homeAndTools: 'Home & tools',
          ListingCategory.foodAndEssentials: 'Food & essentials',
          ListingCategory.skillsAndServices: 'Skills & services',
          ListingCategory.musicHobbiesAndSports: 'Music, hobbies & sports',
          ListingCategory.other: 'Other',
        },
      );
    });

    test('contact preference labels use natural wording', () {
      expect(
        ContactPreference.communityGroup.label,
        'Through a community group',
      );
      expect(
        ContactPreference.publicPlace.label,
        'Meet at a public place',
      );
      expect(
        ContactPreference.mutualConsent.label,
        'Share contact only after mutual consent',
      );
    });

    test('area and status labels are explicit', () {
      expect(
        ApproximateArea.vidyaviharStationEast.label,
        'Vidyavihar station east',
      );
      expect(ListingStatus.open.label, 'Open');
      expect(ListingStatus.closed.label, 'Closed');
    });
  });
}
