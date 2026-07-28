import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

List<Listing> buildSeedListings(DateTime now) {
  DateTime todayAt(int hour, int minute) {
    final intendedTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    return intendedTime.isAfter(now)
        ? intendedTime
        : now.add(const Duration(hours: 2));
  }

  DateTime tomorrowAt(int hour, int minute) {
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  return [
    Listing(
      id: 'sample-guitar-capo',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.need,
      title: 'Guitar capo for evening rehearsal',
      description:
          'I need to borrow a guitar capo for a short rehearsal this evening. '
          'I can return it right after practice.',
      category: ListingCategory.musicHobbiesAndSports,
      approximateArea: ApproximateArea.somaiyaSide,
      contactPreference: ContactPreference.publicPlace,
      createdAt: now.subtract(const Duration(minutes: 35)),
      activeUntil: now.add(const Duration(hours: 3)),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-statistics-notes',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.offer,
      title: 'Statistics notes available to borrow',
      description:
          'A tidy set of introductory statistics notes is available for '
          'anyone revising this week. Please return them in the same condition.',
      category: ListingCategory.booksAndStudy,
      approximateArea: ApproximateArea.somaiyaSide,
      contactPreference: ContactPreference.communityGroup,
      createdAt: now.subtract(const Duration(hours: 2)),
      activeUntil: tomorrowAt(18, 0),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-spare-umbrella',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.offer,
      title: 'Spare umbrella for the evening',
      description:
          'There is a spare folding umbrella available to borrow until '
          'tonight. It is compact but works well in light rain.',
      category: ListingCategory.other,
      approximateArea: ApproximateArea.vidyaviharStationEast,
      contactPreference: ContactPreference.publicPlace,
      createdAt: now.subtract(const Duration(minutes: 50)),
      activeUntil: todayAt(22, 0),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-usb-c-charger',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.need,
      title: 'USB-C laptop charger for two hours',
      description:
          'Looking to borrow a compatible USB-C laptop charger while I finish '
          'an assignment. I only need it for about two hours.',
      category: ListingCategory.electronics,
      approximateArea: ApproximateArea.vidyaviharStationWest,
      contactPreference: ContactPreference.mutualConsent,
      createdAt: now.subtract(const Duration(minutes: 20)),
      activeUntil: now.add(const Duration(hours: 2)),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-entrance-books',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.offer,
      title: 'Entrance-exam books to pass along',
      description:
          'A small set of older entrance-exam preparation books is available '
          'for someone who can use them. Some pages have pencil notes.',
      category: ListingCategory.booksAndStudy,
      approximateArea: ApproximateArea.otherVidyavihar,
      contactPreference: ContactPreference.communityGroup,
      createdAt: now.subtract(const Duration(days: 1)),
      activeUntil: now.add(const Duration(days: 4)),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-flutter-setup',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.offer,
      title: 'Help setting up a Flutter project',
      description:
          'I can help someone get a basic Flutter project running and explain '
          'the folder structure. This is a short peer-help session.',
      category: ListingCategory.skillsAndServices,
      approximateArea: ApproximateArea.somaiyaSide,
      contactPreference: ContactPreference.publicPlace,
      createdAt: now.subtract(const Duration(hours: 5)),
      activeUntil: tomorrowAt(20, 0),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-badminton-shuttles',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.need,
      title: 'Two badminton shuttles near the station',
      description:
          'We are short of two usable badminton shuttles for a casual game '
          'this evening. New or lightly used ones would both help.',
      category: ListingCategory.musicHobbiesAndSports,
      approximateArea: ApproximateArea.vidyaviharStationEast,
      contactPreference: ContactPreference.communityGroup,
      createdAt: now.subtract(const Duration(hours: 1)),
      activeUntil: todayAt(21, 0),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-screwdriver-set',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.offer,
      title: 'Basic screwdriver set to borrow',
      description:
          'A basic flat-head and Phillips screwdriver set is available for a '
          'small repair. Please bring it back by the end of the day.',
      category: ListingCategory.homeAndTools,
      approximateArea: ApproximateArea.vidyaviharStationWest,
      contactPreference: ContactPreference.publicPlace,
      createdAt: now.subtract(const Duration(hours: 3)),
      activeUntil: todayAt(23, 0),
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
    Listing(
      id: 'sample-music-stand',
      neighborhoodId: Neighborhood.vidyavihar.id,
      kind: ListingKind.need,
      title: 'Foldable music stand for practice',
      description:
          'I was looking for a foldable music stand for a practice session. '
          'This request has already been sorted.',
      category: ListingCategory.musicHobbiesAndSports,
      approximateArea: ApproximateArea.otherVidyavihar,
      contactPreference: ContactPreference.mutualConsent,
      createdAt: now.subtract(const Duration(days: 2)),
      activeUntil: now.subtract(const Duration(hours: 4)),
      status: ListingStatus.closed,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.sample,
    ),
  ];
}
