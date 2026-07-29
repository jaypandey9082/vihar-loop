import 'package:vihar_loop/domain/listing.dart';

const endingSoonWindow = Duration(hours: 3);

enum ListingTimeBadge { none, today, endingSoon }

bool listingIsToday(Listing listing, DateTime now) {
  final deadline = listing.activeUntil;
  return listing.status == ListingStatus.open &&
      !deadline.isBefore(now) &&
      deadline.year == now.year &&
      deadline.month == now.month &&
      deadline.day == now.day;
}

bool listingIsEndingSoon(Listing listing, DateTime now) {
  final deadline = listing.activeUntil;
  return listing.status == ListingStatus.open &&
      deadline.isAfter(now) &&
      !deadline.isAfter(now.add(endingSoonWindow));
}

ListingTimeBadge listingTimeBadge(Listing listing, DateTime now) {
  if (listingIsEndingSoon(listing, now)) {
    return ListingTimeBadge.endingSoon;
  }
  if (listingIsToday(listing, now)) {
    return ListingTimeBadge.today;
  }
  return ListingTimeBadge.none;
}
