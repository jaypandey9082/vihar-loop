import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/security/encryption_key_store.dart';

typedef EncryptionKeyGenerator = List<int> Function();

class FlutterSecureValueStore implements SecureValueStore {
  FlutterSecureValueStore({
    FlutterSecureStorage? storage,
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _androidOptions = androidOptions ?? const AndroidOptions(),
        _iosOptions = iosOptions ??
            const IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            );

  final FlutterSecureStorage _storage;
  final AndroidOptions _androidOptions;
  final IOSOptions _iosOptions;

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}

class FlutterSecureEncryptionKeyStore implements EncryptionKeyStore {
  FlutterSecureEncryptionKeyStore({
    SecureValueStore? valueStore,
    EncryptionKeyGenerator? generateKey,
  })  : _valueStore = valueStore ?? FlutterSecureValueStore(),
        _generateKey = generateKey ?? Hive.generateSecureKey;

  static const keyId = 'vihar_loop.listings.encryption_key.v1';
  static const _keyLength = 32;

  final SecureValueStore _valueStore;
  final EncryptionKeyGenerator _generateKey;

  @override
  Future<void> deleteKey() async {
    try {
      await _valueStore.delete(keyId);
    } on Object catch (error) {
      throw LocalStorageException(
        'The local encryption key could not be deleted.',
        cause: error,
      );
    }
  }

  @override
  Future<List<int>> readOrCreateKey() async {
    final String? encoded;
    try {
      encoded = await _valueStore.read(keyId);
    } on Object catch (error) {
      throw LocalStorageException(
        'The local encryption key could not be read.',
        cause: error,
      );
    }

    if (encoded != null) {
      return _decodeAndValidate(encoded);
    }

    final List<int> generated;
    try {
      generated = List<int>.unmodifiable(_generateKey());
    } on Object catch (error) {
      throw LocalStorageException(
        'A local encryption key could not be generated.',
        cause: error,
      );
    }
    _validateLength(generated);

    try {
      await _valueStore.write(keyId, base64Encode(generated));
    } on Object catch (error) {
      throw LocalStorageException(
        'The local encryption key could not be saved.',
        cause: error,
      );
    }

    return generated;
  }

  static List<int> _decodeAndValidate(String encoded) {
    final List<int> decoded;
    try {
      decoded = base64Decode(encoded);
    } on FormatException catch (error) {
      throw LocalStorageException(
        'The stored local encryption key is malformed.',
        cause: error,
      );
    }

    _validateLength(decoded);
    return List<int>.unmodifiable(decoded);
  }

  static void _validateLength(List<int> key) {
    if (key.length != _keyLength) {
      throw const LocalStorageException(
        'The stored local encryption key has an invalid length.',
      );
    }
  }
}
