import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/local/listing_record_codec.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/domain/listing.dart';

import '../../support/listing_fixture.dart';

void main() {
  const codec = ListingRecordCodec();

  group('ListingRecordCodec', () {
    test('round-trips every persisted field and enum value', () {
      for (var index = 0; index < ListingCategory.values.length; index++) {
        final listing = buildTestListing(
          id: 'listing-$index',
          kind: ListingKind.values[index % ListingKind.values.length],
          category: ListingCategory.values[index],
          approximateArea:
              ApproximateArea.values[index % ApproximateArea.values.length],
          contactPreference:
              ContactPreference.values[index % ContactPreference.values.length],
          status: ListingStatus.values[index % ListingStatus.values.length],
          origin: ListingOrigin.values[index % ListingOrigin.values.length],
        );

        expectSameListing(codec.decode(codec.encode(listing)), listing);
      }
    });

    test('writes schema one, stable codes, and UTC ISO-8601 dates', () {
      final record =
          jsonDecode(codec.encode(buildTestListing())) as Map<String, dynamic>;

      expect(record['schemaVersion'], 1);
      expect(record['kind'], 'need');
      expect(record['category'], 'electronics');
      expect(record['approximateArea'], 'somaiya_side');
      expect(record['contactPreference'], 'public_place');
      expect(record['status'], 'open');
      expect(record['origin'], 'local');
      expect(record['createdAt'], endsWith('Z'));
      expect(DateTime.parse(record['createdAt'] as String).isUtc, isTrue);
      expect(
          record.keys,
          containsAll(<String>[
            'id',
            'neighborhoodId',
            'title',
            'description',
            'activeUntil',
            'isSaved',
            'isContacted',
          ]));
    });

    test('preserves UTC instants, local dates, and both boolean values', () {
      final utcListing = buildTestListing(
        createdAt: DateTime.utc(2026, 7, 29, 3, 45, 12, 345),
        activeUntil: DateTime.utc(2026, 7, 30, 18, 15, 1, 9),
        isSaved: false,
        isContacted: true,
      );
      final restored = codec.decode(codec.encode(utcListing));

      expect(restored.createdAt.toUtc(), utcListing.createdAt);
      expect(restored.activeUntil.toUtc(), utcListing.activeUntil);
      expect(restored.createdAt.isUtc, isFalse);
      expect(restored.activeUntil.isUtc, isFalse);
      expect(restored.createdAt.toUtc().millisecond, 345);
      expect(restored.activeUntil.toUtc().millisecond, 9);
      expect(restored.isSaved, isFalse);
      expect(restored.isContacted, isTrue);
    });

    test('rejects non-string, non-object, malformed, and incomplete records',
        () {
      expect(() => codec.decode(42), throwsA(isA<LocalStorageException>()));
      expect(
        () => codec.decode('[]'),
        throwsA(isA<LocalStorageException>()),
      );
      expect(
        () => codec.decode('{not-json'),
        throwsA(isA<LocalStorageException>()),
      );
      expect(
        () => codec.decode(''),
        throwsA(isA<LocalStorageException>()),
      );

      final record = buildRecord();
      record.remove('title');
      expect(
        () => codec.decode(jsonEncode(record)),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('rejects unknown schema and enum codes', () {
      final unknownSchema = buildRecord()..['schemaVersion'] = 2;

      expect(
        () => codec.decode(jsonEncode(unknownSchema)),
        throwsA(isA<LocalStorageException>()),
      );
      for (final field in [
        'kind',
        'category',
        'approximateArea',
        'contactPreference',
        'status',
        'origin',
      ]) {
        final unknownCode = buildRecord()..[field] = 'unknown_code';
        expect(
          () => codec.decode(jsonEncode(unknownCode)),
          throwsA(isA<LocalStorageException>()),
        );
      }
    });

    test('rejects wrong scalar types and non-UTC or malformed dates', () {
      final wrongBool = buildRecord()..['isSaved'] = 'false';
      final localDate = buildRecord()..['createdAt'] = '2026-07-29T09:15:00';
      final badDate = buildRecord()..['activeUntil'] = 'not-a-dateZ';

      for (final record in [wrongBool, localDate, badDate]) {
        expect(
          () => codec.decode(jsonEncode(record)),
          throwsA(isA<LocalStorageException>()),
        );
      }
    });

    test('rejects empty required text and other neighbourhoods', () {
      final otherNeighbourhood = buildRecord()
        ..['neighborhoodId'] = 'elsewhere';

      for (final field in ['id', 'title', 'description']) {
        final blankValue = buildRecord()..[field] = ' ';
        expect(
          () => codec.decode(jsonEncode(blankValue)),
          throwsA(isA<LocalStorageException>()),
        );
      }
      expect(
        () => codec.decode(jsonEncode(otherNeighbourhood)),
        throwsA(isA<LocalStorageException>()),
      );
    });
  });
}

Map<String, dynamic> buildRecord() {
  return jsonDecode(const ListingRecordCodec().encode(buildTestListing()))
      as Map<String, dynamic>;
}
