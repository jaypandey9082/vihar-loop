abstract interface class EncryptionKeyStore {
  Future<List<int>> readOrCreateKey();
}

abstract interface class SecureValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
