import 'package:vihar_loop/domain/listing.dart';

class ListingDraft {
  const ListingDraft({
    required this.kind,
    required this.title,
    required this.description,
    required this.category,
    required this.approximateArea,
    required this.contactPreference,
    required this.activeUntil,
  });

  final ListingKind kind;
  final String title;
  final String description;
  final ListingCategory category;
  final ApproximateArea approximateArea;
  final ContactPreference contactPreference;
  final DateTime activeUntil;

  ListingDraft normalized() {
    return ListingDraft(
      kind: kind,
      title: title.trim(),
      description: description.trim(),
      category: category,
      approximateArea: approximateArea,
      contactPreference: contactPreference,
      activeUntil: activeUntil,
    );
  }
}
