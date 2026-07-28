import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/in_memory_listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 28, 12);
  late InMemoryListingRepository repository;

  setUp(() {
    repository = InMemoryListingRepository(clock: () => fixedNow);
  });

  test('returns nine realistic Vidyavihar listings with unique IDs', () async {
    final listings = await repository.fetchListings();

    expect(listings, hasLength(9));
    expect(listings.map((listing) => listing.id).toSet(), hasLength(9));
    expect(
      listings,
      everyElement(
        isA<Listing>().having(
          (listing) => listing.neighborhoodId,
          'neighborhoodId',
          Neighborhood.vidyavihar.id,
        ),
      ),
    );
  });

  test('uses only approved broad areas and includes required variety',
      () async {
    final listings = await repository.fetchListings();

    expect(
      listings.map((listing) => listing.approximateArea),
      everyElement(isIn(ApproximateArea.values)),
    );
    expect(
      listings.any((listing) => listing.kind == ListingKind.need),
      isTrue,
    );
    expect(
      listings.any((listing) => listing.kind == ListingKind.offer),
      isTrue,
    );
    expect(
      listings.any((listing) => listing.status == ListingStatus.closed),
      isTrue,
    );
    expect(
      listings
          .where((listing) => listing.status == ListingStatus.open)
          .every((listing) => listing.activeUntil.isAfter(fixedNow)),
      isTrue,
    );
  });

  test('returns an unmodifiable collection', () async {
    final listings = await repository.fetchListings();

    expect(
      () => listings.add(listings.first),
      throwsUnsupportedError,
    );
  });

  test('uses the injected clock deterministically', () async {
    final firstLoad = await repository.fetchListings();
    final secondLoad = await repository.fetchListings();
    final urgentListing = firstLoad.singleWhere(
      (listing) => listing.id == 'sample-guitar-capo',
    );

    expect(
        firstLoad.map((listing) => listing.createdAt),
        orderedEquals(
          secondLoad.map((listing) => listing.createdAt),
        ));
    expect(
        firstLoad.map((listing) => listing.activeUntil),
        orderedEquals(
          secondLoad.map((listing) => listing.activeUntil),
        ));
    expect(
      urgentListing.activeUntil,
      fixedNow.add(const Duration(hours: 3)),
    );
    expect(
      firstLoad
          .singleWhere(
            (listing) => listing.id == 'sample-spare-umbrella',
          )
          .activeUntil,
      DateTime(2026, 7, 28, 22),
    );
    expect(
      firstLoad.every((listing) => listing.origin == ListingOrigin.sample),
      isTrue,
    );
  });
}
