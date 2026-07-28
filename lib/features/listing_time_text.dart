import 'package:flutter/material.dart';
import 'package:vihar_loop/domain/listing.dart';

String listingTimeText(BuildContext context, Listing listing) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(listing.activeUntil);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(listing.activeUntil),
  );
  return '$date at $time';
}
