import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/security/encryption_key_store.dart';
import 'package:vihar_loop/security/flutter_secure_encryption_key_store.dart';

void main() {
  group('FlutterSecureEncryptionKeyStore', () {
    test('reads an existing 32-byte Base64 key without regenerating it',
        () async {
      final bytes = List<int>.generate(32, (index) => index);
      final values = _FakeSecureValueStore(
        existingValue: base64Encode(bytes),
      );
      var generationCount = 0;
      final store = FlutterSecureEncryptionKeyStore(
        valueStore: values,
        generateKey: () {
          generationCount++;
          return List<int>.filled(32, 99);
        },
      );

      expect(await store.readOrCreateKey(), orderedEquals(bytes));
      expect(generationCount, 0);
      expect(values.writeCount, 0);
      expect(values.lastReadKey, FlutterSecureEncryptionKeyStore.keyId);
    });

    test('generates and stores a new random key exactly once when absent',
        () async {
      final generated = List<int>.generate(32, (index) => 255 - index);
      final values = _FakeSecureValueStore();
      var generationCount = 0;
      final store = FlutterSecureEncryptionKeyStore(
        valueStore: values,
        generateKey: () {
          generationCount++;
          return generated;
        },
      );

      expect(await store.readOrCreateKey(), orderedEquals(generated));
      expect(generationCount, 1);
      expect(values.writeCount, 1);
      expect(values.lastWriteKey, FlutterSecureEncryptionKeyStore.keyId);
      expect(base64Decode(values.lastWriteValue!), orderedEquals(generated));
    });

    test('malformed stored values fail without replacement or regeneration',
        () async {
      for (final invalid in [
        'not base64!!!',
        base64Encode(List<int>.filled(31, 7)),
        base64Encode(List<int>.filled(33, 7)),
      ]) {
        final values = _FakeSecureValueStore(existingValue: invalid);
        var generationCount = 0;
        final store = FlutterSecureEncryptionKeyStore(
          valueStore: values,
          generateKey: () {
            generationCount++;
            return List<int>.filled(32, 1);
          },
        );

        await expectLater(
          store.readOrCreateKey(),
          throwsA(isA<LocalStorageException>()),
        );
        expect(generationCount, 0);
        expect(values.writeCount, 0);
      }
    });

    test('rejects an invalid generated key before writing it', () async {
      final values = _FakeSecureValueStore();
      final store = FlutterSecureEncryptionKeyStore(
        valueStore: values,
        generateKey: () => List<int>.filled(16, 1),
      );

      await expectLater(
        store.readOrCreateKey(),
        throwsA(isA<LocalStorageException>()),
      );
      expect(values.writeCount, 0);
    });

    test('surfaces secure read and write failures with secret-safe messages',
        () async {
      const secret = 'super-sensitive-platform-value';
      final readFailure = FlutterSecureEncryptionKeyStore(
        valueStore: _FakeSecureValueStore(readError: Exception(secret)),
      );
      final writeFailure = FlutterSecureEncryptionKeyStore(
        valueStore: _FakeSecureValueStore(writeError: Exception(secret)),
        generateKey: () => List<int>.filled(32, 4),
      );

      for (final store in [readFailure, writeFailure]) {
        try {
          await store.readOrCreateKey();
          fail('Expected secure storage to fail.');
        } on LocalStorageException catch (error) {
          expect(error.toString(), isNot(contains(secret)));
        }
      }
    });

    test('deleteKey deletes only the ViharLoop value', () async {
      final values = _MapSecureValueStore({
        FlutterSecureEncryptionKeyStore.keyId:
            base64Encode(List<int>.filled(32, 7)),
        'unrelated.future.key': 'keep-me',
      });
      final store = FlutterSecureEncryptionKeyStore(valueStore: values);

      await store.deleteKey();

      expect(values.values[FlutterSecureEncryptionKeyStore.keyId], isNull);
      expect(values.values['unrelated.future.key'], 'keep-me');
      expect(values.deletedKeys, [FlutterSecureEncryptionKeyStore.keyId]);
    });

    test('delete does not read malformed or unavailable values', () async {
      for (final values in [
        _FakeSecureValueStore(existingValue: 'not base64!!!'),
        _FakeSecureValueStore(readError: Exception('read unavailable')),
        _FakeSecureValueStore(),
      ]) {
        final store = FlutterSecureEncryptionKeyStore(valueStore: values);

        await store.deleteKey();

        expect(values.lastReadKey, isNull);
        expect(values.deleteCount, 1);
        expect(
          values.lastDeletedKey,
          FlutterSecureEncryptionKeyStore.keyId,
        );
      }
    });

    test('delete failure is wrapped without leaking platform content',
        () async {
      const secret = 'stored-secret-value';
      final store = FlutterSecureEncryptionKeyStore(
        valueStore: _FakeSecureValueStore(
          deleteError: Exception(secret),
        ),
      );

      await expectLater(
        store.deleteKey(),
        throwsA(
          isA<LocalStorageException>()
              .having(
                (error) => error.toString(),
                'safe text',
                contains('The local encryption key could not be deleted.'),
              )
              .having(
                (error) => error.toString(),
                'does not leak',
                isNot(contains(secret)),
              ),
        ),
      );
    });

    test('readOrCreate after deletion writes a different 32-byte key',
        () async {
      final original = List<int>.filled(32, 1);
      final replacement = List<int>.filled(32, 2);
      final values = _MapSecureValueStore({
        FlutterSecureEncryptionKeyStore.keyId: base64Encode(original),
      });
      final store = FlutterSecureEncryptionKeyStore(
        valueStore: values,
        generateKey: () => replacement,
      );

      expect(await store.readOrCreateKey(), orderedEquals(original));
      await store.deleteKey();
      final next = await store.readOrCreateKey();

      expect(next, hasLength(32));
      expect(next, orderedEquals(replacement));
      expect(next, isNot(orderedEquals(original)));
    });
  });
}

class _FakeSecureValueStore implements SecureValueStore {
  _FakeSecureValueStore({
    this.existingValue,
    this.readError,
    this.writeError,
    this.deleteError,
  });

  final String? existingValue;
  final Object? readError;
  final Object? writeError;
  final Object? deleteError;

  int writeCount = 0;
  int deleteCount = 0;
  String? lastReadKey;
  String? lastWriteKey;
  String? lastWriteValue;
  String? lastDeletedKey;

  @override
  Future<void> delete(String key) async {
    if (deleteError case final error?) {
      throw error;
    }
    deleteCount++;
    lastDeletedKey = key;
  }

  @override
  Future<String?> read(String key) async {
    lastReadKey = key;
    if (readError case final error?) {
      throw error;
    }
    return existingValue;
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeError case final error?) {
      throw error;
    }
    writeCount++;
    lastWriteKey = key;
    lastWriteValue = value;
  }
}

class _MapSecureValueStore implements SecureValueStore {
  _MapSecureValueStore(Map<String, String> values) : values = {...values};

  final Map<String, String> values;
  final List<String> deletedKeys = [];

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
