import 'dart:collection';

import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/data/seed_listings.dart';
import 'package:vihar_loop/domain/listing.dart';

typedef Clock = DateTime Function();

class InMemoryListingRepository implements ListingRepository {
  InMemoryListingRepository({Clock? clock}) : _clock = clock ?? DateTime.now;

  final Clock _clock;

  @override
  Future<List<Listing>> fetchListings() async {
    return UnmodifiableListView(buildSeedListings(_clock()));
  }
}
