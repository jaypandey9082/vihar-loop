import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> fetchListings();

  Future<Listing> createListing(ListingDraft draft);

  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  });

  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  });

  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  });
}

class ListingNotFoundException implements Exception {
  const ListingNotFoundException();
}

class ListingStatusChangeNotAllowedException implements Exception {
  const ListingStatusChangeNotAllowedException();
}
