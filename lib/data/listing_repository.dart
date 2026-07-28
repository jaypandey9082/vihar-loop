import 'package:vihar_loop/domain/listing.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> fetchListings();
}
