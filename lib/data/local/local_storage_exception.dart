class LocalStorageException implements Exception {
  const LocalStorageException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'LocalStorageException: $message';
}
