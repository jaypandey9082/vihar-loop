import 'package:vihar_loop/domain/listing_draft.dart';

class ListingDraftValidator {
  const ListingDraftValidator();

  static const contactInformationError =
      'Remove phone numbers, email addresses, or links. '
      'Choose a contact preference instead.';

  String? titleError(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Add a short title.';
    }
    if (title.length < 5) {
      return 'Use at least 5 characters.';
    }
    if (title.length > 80) {
      return 'Keep the title under 80 characters.';
    }
    if (title.contains('\n') || title.contains('\r')) {
      return 'Keep the title on one line.';
    }
    if (_containsContactInformation(title)) {
      return contactInformationError;
    }
    return null;
  }

  String? descriptionError(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Describe what you need or are offering.';
    }
    if (description.length < 15) {
      return 'Add a little more detail so people know what to expect.';
    }
    if (description.length > 500) {
      return 'Keep the description under 500 characters.';
    }
    if (_containsContactInformation(description)) {
      return contactInformationError;
    }
    return null;
  }

  String? activeUntilError(DateTime? value, DateTime now) {
    if (value == null) {
      return 'Choose when this need or offer ends.';
    }
    if (value.isBefore(now.add(const Duration(minutes: 15)))) {
      return 'Choose a time at least 15 minutes from now.';
    }
    if (value.isAfter(now.add(const Duration(days: 7)))) {
      return 'Keep the listing within the next 7 days.';
    }
    return null;
  }

  bool isValid(ListingDraft draft, DateTime now) {
    return titleError(draft.title) == null &&
        descriptionError(draft.description) == null &&
        activeUntilError(draft.activeUntil, now) == null;
  }

  void validateOrThrow(ListingDraft draft, DateTime now) {
    if (!isValid(draft, now)) {
      throw const InvalidListingDraftException();
    }
  }

  bool _containsContactInformation(String value) {
    return RegExp(
          r'(?:https?://|www\.)\S+',
          caseSensitive: false,
        ).hasMatch(value) ||
        RegExp(
          r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
          caseSensitive: false,
        ).hasMatch(value) ||
        RegExp(
          r'(?<!\d)(?:\+91[\s-]?)?[6-9]\d{4}[\s-]?\d{5}(?!\d)',
        ).hasMatch(value);
  }
}

class InvalidListingDraftException implements Exception {
  const InvalidListingDraftException();

  @override
  String toString() => 'The listing draft is invalid.';
}
