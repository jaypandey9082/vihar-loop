import 'dart:convert';

import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

class ListingRecordCodec {
  const ListingRecordCodec();

  static const schemaVersion = 1;

  String encode(Listing listing) {
    _validateListing(listing);

    return jsonEncode({
      'schemaVersion': schemaVersion,
      'id': listing.id,
      'neighborhoodId': listing.neighborhoodId,
      'kind': _kindCode(listing.kind),
      'title': listing.title,
      'description': listing.description,
      'category': _categoryCode(listing.category),
      'approximateArea': _areaCode(listing.approximateArea),
      'contactPreference': _contactCode(listing.contactPreference),
      'createdAt': listing.createdAt.toUtc().toIso8601String(),
      'activeUntil': listing.activeUntil.toUtc().toIso8601String(),
      'status': _statusCode(listing.status),
      'isSaved': listing.isSaved,
      'isContacted': listing.isContacted,
      'origin': _originCode(listing.origin),
    });
  }

  Listing decode(Object? record) {
    if (record is! String) {
      throw const LocalStorageException(
        'A local listing record has an invalid value type.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(record);
    } on Object catch (error) {
      throw LocalStorageException(
        'A local listing record is not valid JSON.',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const LocalStorageException(
        'A local listing record has an invalid structure.',
      );
    }

    final schema = decoded['schemaVersion'];
    if (schema is! int || schema != schemaVersion) {
      throw const LocalStorageException(
        'A local listing record uses an unsupported schema version.',
      );
    }

    final listing = Listing(
      id: _requiredString(decoded, 'id'),
      neighborhoodId: _requiredString(decoded, 'neighborhoodId'),
      kind: _parseCode(
        decoded,
        'kind',
        const {
          'need': ListingKind.need,
          'offer': ListingKind.offer,
        },
      ),
      title: _requiredString(decoded, 'title'),
      description: _requiredString(decoded, 'description'),
      category: _parseCode(
        decoded,
        'category',
        const {
          'books_study': ListingCategory.booksAndStudy,
          'electronics': ListingCategory.electronics,
          'home_tools': ListingCategory.homeAndTools,
          'food_essentials': ListingCategory.foodAndEssentials,
          'skills_services': ListingCategory.skillsAndServices,
          'music_hobbies_sports': ListingCategory.musicHobbiesAndSports,
          'other': ListingCategory.other,
        },
      ),
      approximateArea: _parseCode(
        decoded,
        'approximateArea',
        const {
          'somaiya_side': ApproximateArea.somaiyaSide,
          'vidyavihar_station_east': ApproximateArea.vidyaviharStationEast,
          'vidyavihar_station_west': ApproximateArea.vidyaviharStationWest,
          'other_vidyavihar': ApproximateArea.otherVidyavihar,
        },
      ),
      contactPreference: _parseCode(
        decoded,
        'contactPreference',
        const {
          'community_group': ContactPreference.communityGroup,
          'public_place': ContactPreference.publicPlace,
          'mutual_consent': ContactPreference.mutualConsent,
        },
      ),
      createdAt: _requiredDateTime(decoded, 'createdAt'),
      activeUntil: _requiredDateTime(decoded, 'activeUntil'),
      status: _parseCode(
        decoded,
        'status',
        const {
          'open': ListingStatus.open,
          'closed': ListingStatus.closed,
        },
      ),
      isSaved: _requiredBool(decoded, 'isSaved'),
      isContacted: _requiredBool(decoded, 'isContacted'),
      origin: _parseCode(
        decoded,
        'origin',
        const {
          'sample': ListingOrigin.sample,
          'local': ListingOrigin.local,
        },
      ),
    );

    _validateListing(listing);
    return listing;
  }

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.trim().isEmpty) {
      throw LocalStorageException(
        'A local listing record has an invalid $field field.',
      );
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! bool) {
      throw LocalStorageException(
        'A local listing record has an invalid $field field.',
      );
    }
    return value;
  }

  static DateTime _requiredDateTime(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];
    if (value is! String || !value.endsWith('Z')) {
      throw LocalStorageException(
        'A local listing record has an invalid $field field.',
      );
    }

    try {
      return DateTime.parse(value).toLocal();
    } on FormatException catch (error) {
      throw LocalStorageException(
        'A local listing record has an invalid $field field.',
        cause: error,
      );
    }
  }

  static T _parseCode<T>(
    Map<String, dynamic> map,
    String field,
    Map<String, T> values,
  ) {
    final code = map[field];
    if (code is! String || !values.containsKey(code)) {
      throw LocalStorageException(
        'A local listing record has an unknown $field code.',
      );
    }
    return values[code] as T;
  }

  static void _validateListing(Listing listing) {
    if (listing.id.trim().isEmpty ||
        listing.title.trim().isEmpty ||
        listing.description.trim().isEmpty ||
        listing.neighborhoodId != Neighborhood.vidyavihar.id) {
      throw const LocalStorageException(
        'A listing cannot be stored because required data is invalid.',
      );
    }
  }

  static String _kindCode(ListingKind value) => switch (value) {
        ListingKind.need => 'need',
        ListingKind.offer => 'offer',
      };

  static String _categoryCode(ListingCategory value) => switch (value) {
        ListingCategory.booksAndStudy => 'books_study',
        ListingCategory.electronics => 'electronics',
        ListingCategory.homeAndTools => 'home_tools',
        ListingCategory.foodAndEssentials => 'food_essentials',
        ListingCategory.skillsAndServices => 'skills_services',
        ListingCategory.musicHobbiesAndSports => 'music_hobbies_sports',
        ListingCategory.other => 'other',
      };

  static String _areaCode(ApproximateArea value) => switch (value) {
        ApproximateArea.somaiyaSide => 'somaiya_side',
        ApproximateArea.vidyaviharStationEast => 'vidyavihar_station_east',
        ApproximateArea.vidyaviharStationWest => 'vidyavihar_station_west',
        ApproximateArea.otherVidyavihar => 'other_vidyavihar',
      };

  static String _contactCode(ContactPreference value) => switch (value) {
        ContactPreference.communityGroup => 'community_group',
        ContactPreference.publicPlace => 'public_place',
        ContactPreference.mutualConsent => 'mutual_consent',
      };

  static String _statusCode(ListingStatus value) => switch (value) {
        ListingStatus.open => 'open',
        ListingStatus.closed => 'closed',
      };

  static String _originCode(ListingOrigin value) => switch (value) {
        ListingOrigin.sample => 'sample',
        ListingOrigin.local => 'local',
      };
}
