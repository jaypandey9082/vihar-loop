import 'package:vihar_loop/domain/listing.dart';

abstract interface class ListingLocalStore {
  Future<void> seedIfRequired(List<Listing> listings);

  Future<List<Listing>> readAll();
}
