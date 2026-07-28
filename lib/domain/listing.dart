enum ListingKind { need, offer }

enum ListingCategory {
  booksAndStudy,
  electronics,
  homeAndTools,
  foodAndEssentials,
  skillsAndServices,
  musicHobbiesAndSports,
  other,
}

enum ApproximateArea {
  somaiyaSide,
  vidyaviharStationEast,
  vidyaviharStationWest,
  otherVidyavihar,
}

enum ContactPreference {
  communityGroup,
  publicPlace,
  mutualConsent,
}

enum ListingStatus { open, closed }

enum ListingOrigin { sample, local }

extension ListingKindLabel on ListingKind {
  String get label => switch (this) {
        ListingKind.need => 'Need',
        ListingKind.offer => 'Offer',
      };

  String get activeUntilLabel => switch (this) {
        ListingKind.need => 'Needed by',
        ListingKind.offer => 'Available until',
      };
}

extension ListingCategoryLabel on ListingCategory {
  String get label => switch (this) {
        ListingCategory.booksAndStudy => 'Books & study',
        ListingCategory.electronics => 'Electronics',
        ListingCategory.homeAndTools => 'Home & tools',
        ListingCategory.foodAndEssentials => 'Food & essentials',
        ListingCategory.skillsAndServices => 'Skills & services',
        ListingCategory.musicHobbiesAndSports => 'Music, hobbies & sports',
        ListingCategory.other => 'Other',
      };
}

extension ApproximateAreaLabel on ApproximateArea {
  String get label => switch (this) {
        ApproximateArea.somaiyaSide => 'Somaiya side',
        ApproximateArea.vidyaviharStationEast => 'Vidyavihar station east',
        ApproximateArea.vidyaviharStationWest => 'Vidyavihar station west',
        ApproximateArea.otherVidyavihar => 'Elsewhere in Vidyavihar',
      };
}

extension ContactPreferenceLabel on ContactPreference {
  String get label => switch (this) {
        ContactPreference.communityGroup => 'Through a community group',
        ContactPreference.publicPlace => 'Meet at a public place',
        ContactPreference.mutualConsent =>
          'Share contact only after mutual consent',
      };
}

extension ListingStatusLabel on ListingStatus {
  String get label => switch (this) {
        ListingStatus.open => 'Open',
        ListingStatus.closed => 'Closed',
      };
}

class Listing {
  const Listing({
    required this.id,
    required this.neighborhoodId,
    required this.kind,
    required this.title,
    required this.description,
    required this.category,
    required this.approximateArea,
    required this.contactPreference,
    required this.createdAt,
    required this.activeUntil,
    required this.status,
    required this.isSaved,
    required this.isContacted,
    required this.origin,
  });

  final String id;
  final String neighborhoodId;
  final ListingKind kind;
  final String title;
  final String description;
  final ListingCategory category;
  final ApproximateArea approximateArea;
  final ContactPreference contactPreference;
  final DateTime createdAt;
  final DateTime activeUntil;
  final ListingStatus status;
  final bool isSaved;
  final bool isContacted;
  final ListingOrigin origin;
}
