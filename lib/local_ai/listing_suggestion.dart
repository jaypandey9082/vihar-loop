import 'package:vihar_loop/domain/listing.dart';

enum ListingSuggestionSource {
  onDeviceModel,
  deterministicFallback,
}

extension ListingSuggestionSourceLabel on ListingSuggestionSource {
  String get label => switch (this) {
        ListingSuggestionSource.onDeviceModel => 'On-device model',
        ListingSuggestionSource.deterministicFallback =>
          'Built-in offline rules',
      };
}

class ListingSuggestion {
  const ListingSuggestion({
    required this.kind,
    required this.title,
    required this.category,
    required this.source,
  });

  final ListingKind kind;
  final String title;
  final ListingCategory category;
  final ListingSuggestionSource source;
}
