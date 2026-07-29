import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:vihar_loop/data/local/listing_local_store.dart';
import 'package:vihar_loop/data/local/listing_record_codec.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/security/encryption_key_store.dart';

typedef HiveInitializer = Future<void> Function(HiveInterface hive);
typedef HiveBoxDeleter = Future<void> Function(
  HiveInterface hive,
  String boxName,
);

class EncryptedHiveListingStore implements ListingLocalStore {
  EncryptedHiveListingStore({
    required EncryptionKeyStore keyStore,
    ListingRecordCodec codec = const ListingRecordCodec(),
    HiveInterface? hive,
    HiveInitializer? initializeHive,
    HiveBoxDeleter? deleteBox,
    String boxName = defaultBoxName,
  })  : _keyStore = keyStore,
        _codec = codec,
        _hive = hive ?? Hive,
        _initializeHive = initializeHive ?? _initializeFlutterHive,
        _deleteBox = deleteBox ?? _deleteHiveBox,
        _boxName = boxName;

  static const defaultBoxName = 'vihar_loop_listings_v1';
  static const listingKeyPrefix = 'listing:';
  static const seedVersionKey = 'meta:seed_version';
  static const seedVersion = '1';

  final EncryptionKeyStore _keyStore;
  final ListingRecordCodec _codec;
  final HiveInterface _hive;
  final HiveInitializer _initializeHive;
  final HiveBoxDeleter _deleteBox;
  final String _boxName;

  Future<Box<String>>? _boxFuture;

  @override
  Future<void> deleteAllData() async {
    _boxFuture = null;
    try {
      await _initializeHive(_hive);
      await _deleteBox(_hive, _boxName);
    } on Object catch (error) {
      throw LocalStorageException(
        'Encrypted local listings could not be deleted.',
        cause: error,
      );
    }

    try {
      await _keyStore.deleteKey();
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'The local encryption key could not be deleted.',
        cause: error,
      );
    }
  }

  @override
  Future<void> seedIfRequired(List<Listing> listings) async {
    final box = await _openBox();
    final String? marker;
    try {
      marker = box.get(seedVersionKey);
    } on Object catch (error) {
      throw LocalStorageException(
        'The local seed version could not be read.',
        cause: error,
      );
    }

    if (marker == seedVersion) {
      return;
    }
    if (marker != null) {
      throw const LocalStorageException(
        'The local seed data uses an unsupported version.',
      );
    }

    final records = <String, String>{};
    for (final listing in listings) {
      final recordKey = '$listingKeyPrefix${listing.id}';
      if (records.containsKey(recordKey)) {
        throw const LocalStorageException(
          'Seed listings contain a duplicate identifier.',
        );
      }
      records[recordKey] = _codec.encode(listing);
    }

    try {
      await box.putAll(records);
      await box.put(seedVersionKey, seedVersion);
    } on Object catch (error) {
      throw LocalStorageException(
        'Local listings could not be initialized.',
        cause: error,
      );
    }
  }

  @override
  Future<List<Listing>> readAll() async {
    final Box<String> box;
    try {
      box = await _openBox();
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'Encrypted local storage could not be opened.',
        cause: error,
      );
    }

    final listings = <Listing>[];
    final logicalIds = <String>{};

    try {
      for (final key in box.keys) {
        if (key == seedVersionKey) {
          continue;
        }
        if (key is! String || !key.startsWith(listingKeyPrefix)) {
          throw const LocalStorageException(
            'Encrypted local storage contains an unknown record.',
          );
        }

        final listing = _decodeListingRecord(key, box.get(key));
        if (!logicalIds.add(listing.id)) {
          throw const LocalStorageException(
            'Encrypted local storage contains duplicate listing identifiers.',
          );
        }
        listings.add(listing);
      }
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'Local listings could not be read.',
        cause: error,
      );
    }

    return List<Listing>.unmodifiable(listings);
  }

  @override
  Future<Listing?> readById(String id) async {
    final box = await _openBox();
    final key = '$listingKeyPrefix$id';

    try {
      if (!box.containsKey(key)) {
        return null;
      }
      return _decodeListingRecord(key, box.get(key));
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'The local listing could not be read.',
        cause: error,
      );
    }
  }

  @override
  Future<void> insert(Listing listing) async {
    final box = await _openBox();
    final key = '$listingKeyPrefix${listing.id}';

    try {
      if (box.containsKey(key)) {
        throw const LocalStorageException(
          'A local listing with this identifier already exists.',
        );
      }
      await box.put(key, _codec.encode(listing));
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'The local listing could not be created.',
        cause: error,
      );
    }
  }

  @override
  Future<void> update(Listing listing) async {
    final box = await _openBox();
    final key = '$listingKeyPrefix${listing.id}';

    try {
      if (!box.containsKey(key)) {
        throw const LocalStorageException(
          'The local listing to update does not exist.',
        );
      }

      _decodeListingRecord(key, box.get(key));
      final record = _codec.encode(listing);
      await box.put(key, record);
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'The local listing could not be updated.',
        cause: error,
      );
    }
  }

  Future<void> close() async {
    final pending = _boxFuture;
    _boxFuture = null;
    if (pending != null) {
      final box = await pending;
      await box.close();
    }
  }

  Future<Box<String>> _openBox() async {
    final cached = _boxFuture;
    if (cached != null) {
      return cached;
    }

    final pending = _createBox();
    _boxFuture = pending;
    try {
      return await pending;
    } on Object {
      if (identical(_boxFuture, pending)) {
        _boxFuture = null;
      }
      rethrow;
    }
  }

  Future<Box<String>> _createBox() async {
    try {
      await _initializeHive(_hive);
      final key = await _keyStore.readOrCreateKey();
      if (key.length != 32) {
        throw const LocalStorageException(
          'The local encryption key has an invalid length.',
        );
      }
      return await _hive.openBox<String>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
        crashRecovery: false,
      );
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException(
        'Encrypted local storage could not be opened.',
        cause: error,
      );
    }
  }

  static Future<void> _initializeFlutterHive(HiveInterface hive) {
    return hive.initFlutter();
  }

  static Future<void> _deleteHiveBox(
    HiveInterface hive,
    String boxName,
  ) {
    return hive.deleteBoxFromDisk(boxName);
  }

  Listing _decodeListingRecord(String key, Object? record) {
    final listing = _codec.decode(record);
    final keyId = key.substring(listingKeyPrefix.length);
    if (listing.id != keyId) {
      throw const LocalStorageException(
        'A local listing record does not match its storage key.',
      );
    }
    return listing;
  }
}
