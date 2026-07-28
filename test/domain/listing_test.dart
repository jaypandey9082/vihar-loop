import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';

void main() {
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
