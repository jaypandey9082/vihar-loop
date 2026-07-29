import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_timing.dart';

import '../support/listing_fixture.dart';

void main() {
  final now = DateTime(2026, 7, 30, 12);

  Listing at(
    DateTime deadline, {
    ListingStatus status = ListingStatus.open,
    ListingKind kind = ListingKind.need,
  }) {
    return buildTestListing(
      activeUntil: deadline,
      status: status,
      kind: kind,
    );
  }

  test('Today includes future needs and offers on this local date only', () {
    expect(listingIsToday(at(DateTime(2026, 7, 30, 18)), now), isTrue);
    expect(
      listingIsToday(
        at(DateTime(2026, 7, 30, 18), kind: ListingKind.offer),
        now,
      ),
      isTrue,
    );
    expect(listingIsToday(at(DateTime(2026, 7, 30, 11, 59)), now), isFalse);
    expect(listingIsToday(at(DateTime(2026, 7, 31, 1)), now), isFalse);
    expect(
      listingIsToday(
        at(DateTime(2026, 7, 30, 18), status: ListingStatus.closed),
        now,
      ),
      isFalse,
    );
  });

  test('Ending soon uses a strict-now and inclusive three-hour window', () {
    expect(
      listingIsEndingSoon(at(now.add(const Duration(minutes: 1))), now),
      isTrue,
    );
    expect(
      listingIsEndingSoon(at(now.add(const Duration(hours: 3))), now),
      isTrue,
    );
    expect(
      listingIsEndingSoon(
        at(now.add(const Duration(hours: 3, minutes: 1))),
        now,
      ),
      isFalse,
    );
    expect(listingIsEndingSoon(at(now), now), isFalse);
    expect(
      listingIsEndingSoon(at(now.subtract(const Duration(seconds: 1))), now),
      isFalse,
    );
    expect(
      listingIsEndingSoon(
        at(now.add(const Duration(hours: 1)), status: ListingStatus.closed),
        now,
      ),
      isFalse,
    );
  });

  test('badge prioritizes Ending soon, then Today, then none', () {
    expect(
      listingTimeBadge(at(now.add(const Duration(hours: 2))), now),
      ListingTimeBadge.endingSoon,
    );
    expect(
      listingTimeBadge(at(DateTime(2026, 7, 30, 20)), now),
      ListingTimeBadge.today,
    );
    expect(
      listingTimeBadge(at(DateTime(2026, 7, 31, 12)), now),
      ListingTimeBadge.none,
    );
    expect(
      listingTimeBadge(
        at(DateTime(2026, 7, 30, 13), status: ListingStatus.closed),
        now,
      ),
      ListingTimeBadge.none,
    );
  });

  test('calendar boundary uses local dates', () {
    final nearMidnight = DateTime(2026, 7, 30, 23, 30);
    final tomorrow = at(DateTime(2026, 7, 31, 0, 30));

    expect(listingIsToday(tomorrow, nearMidnight), isFalse);
    expect(listingIsEndingSoon(tomorrow, nearMidnight), isTrue);
  });
}
