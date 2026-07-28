import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

Listing buildTestListing({
  String id = 'test-listing',
  ListingKind kind = ListingKind.need,
  ListingCategory category = ListingCategory.electronics,
  ApproximateArea approximateArea = ApproximateArea.somaiyaSide,
  ContactPreference contactPreference = ContactPreference.publicPlace,
  ListingStatus status = ListingStatus.open,
  ListingOrigin origin = ListingOrigin.local,
  DateTime? createdAt,
  DateTime? activeUntil,
  bool isSaved = true,
  bool isContacted = false,
}) {
  return Listing(
    id: id,
    neighborhoodId: Neighborhood.vidyavihar.id,
    kind: kind,
    title: "A neighbour's café charger — परीक्षण",
    description:
        'A unique description: punctuation, apostrophe’s, and Unicode ✓.',
    category: category,
    approximateArea: approximateArea,
    contactPreference: contactPreference,
    createdAt: createdAt ?? DateTime(2026, 7, 29, 9, 15),
    activeUntil: activeUntil ?? DateTime(2026, 7, 29, 18, 45),
    status: status,
    isSaved: isSaved,
    isContacted: isContacted,
    origin: origin,
  );
}

void expectSameListing(Listing actual, Listing expected) {
  expect(actual.id, expected.id);
  expect(actual.neighborhoodId, expected.neighborhoodId);
  expect(actual.kind, expected.kind);
  expect(actual.title, expected.title);
  expect(actual.description, expected.description);
  expect(actual.category, expected.category);
  expect(actual.approximateArea, expected.approximateArea);
  expect(actual.contactPreference, expected.contactPreference);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.activeUntil, expected.activeUntil);
  expect(actual.status, expected.status);
  expect(actual.isSaved, expected.isSaved);
  expect(actual.isContacted, expected.isContacted);
  expect(actual.origin, expected.origin);
}
