import 'package:flutter/material.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/local/encrypted_hive_listing_store.dart';
import 'package:vihar_loop/data/local_listing_repository.dart';
import 'package:vihar_loop/security/flutter_secure_encryption_key_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final Clock clock = DateTime.now;
  final repository = LocalListingRepository(
    store: EncryptedHiveListingStore(
      keyStore: FlutterSecureEncryptionKeyStore(),
    ),
    clock: clock,
  );
  runApp(ViharLoopApp(listingRepository: repository, clock: clock));
}
