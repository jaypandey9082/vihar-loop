enum ListingPrivacyIssue {
  directContact,
  preciseLocation,
}

class ListingPrivacyValidator {
  const ListingPrivacyValidator();

  static final RegExp _url = RegExp(
    r'(?:https?://|www\.)\S+',
    caseSensitive: false,
  );
  static final RegExp _email = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _phone = RegExp(
    r'(?<!\d)(?:\+?91[\s().-]*)?[6-9](?:[\s().-]*\d){9}(?!\d)',
  );
  static final RegExp _socialHandle = RegExp(
    r'(?<![A-Z0-9_@])@[A-Z0-9_][A-Z0-9_.]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _paymentId = RegExp(
    r'\b[A-Z0-9][A-Z0-9._-]{1,}@(UPI|YBL|PAYTM|OK[A-Z]+|IBL|APL)\b',
    caseSensitive: false,
  );

  static final RegExp _numberedPlace = RegExp(
    r'\b(?:flat|room|house|shop|unit|door)\s*'
    r'(?:no\.?\s*)?(?:[A-Z]{1,2}-\d{1,4}|\d{1,4}[A-Z]?(?:-\d{1,4})?)\b',
    caseSensitive: false,
  );
  static final RegExp _wing = RegExp(
    r'\b(?:wing\s+[A-Z0-9]{1,3}|[A-Z0-9]{1,3}\s+wing)\b',
    caseSensitive: false,
  );
  static final RegExp _blockOrTower = RegExp(
    r'\b(?:block|tower)\s+[A-Z0-9]{1,3}\b',
    caseSensitive: false,
  );
  static final RegExp _floor = RegExp(
    r'\b(?:\d{1,3}(?:st|nd|rd|th)\s+floor|'
    r'floor\s+(?:no\.?\s*)?[A-Z0-9-]{1,5})\b',
    caseSensitive: false,
  );
  static final RegExp _streetAddress = RegExp(
    r"\b\d{1,4}\s+[A-Z][A-Z .'-]{0,40}\s+"
    r'(?:road|rd|street|st|lane|ln|avenue|ave)\b',
    caseSensitive: false,
  );
  static final RegExp _numberedStreet = RegExp(
    r'\b(?:road|street|lane|avenue)\s+(?:no\.?\s*)?\d{1,4}[A-Z]?\b',
    caseSensitive: false,
  );
  static final RegExp _pinCode = RegExp(
    r'\b(?:pin(?:code)?|postal\s+code)\s*[:#-]?\s*[1-9]\d{5}\b',
    caseSensitive: false,
  );
  static final RegExp _namedBuilding = RegExp(
    r'\bbuilding\s+name\s*[:#-]\s*\S+',
    caseSensitive: false,
  );
  static final RegExp _numberedSociety = RegExp(
    r'\bsociety\s+no\.?\s*[:#-]?\s*[A-Z0-9-]+\b',
    caseSensitive: false,
  );
  static final RegExp _coordinatePair = RegExp(
    r'(?<![\d.])([+-]?\d{1,3}\.\d{3,})\s*[,;/]\s*'
    r'([+-]?\d{1,3}\.\d{3,})(?![\d.])',
  );
  static final RegExp _labeledCoordinates = RegExp(
    r'\b(?:lat|latitude)\s*[:=]?\s*([+-]?\d{1,3}(?:\.\d+)?)'
    r'\s*[,; ]+\s*(?:lon|lng|longitude)\s*[:=]?\s*'
    r'([+-]?\d{1,3}(?:\.\d+)?)',
    caseSensitive: false,
  );

  ListingPrivacyIssue? firstIssue(String value) {
    if (_containsDirectContact(value)) {
      return ListingPrivacyIssue.directContact;
    }
    if (_containsPreciseLocation(value)) {
      return ListingPrivacyIssue.preciseLocation;
    }
    return null;
  }

  bool _containsDirectContact(String value) {
    return _url.hasMatch(value) ||
        _email.hasMatch(value) ||
        _phone.hasMatch(value) ||
        _socialHandle.hasMatch(value) ||
        _paymentId.hasMatch(value);
  }

  bool _containsPreciseLocation(String value) {
    return _numberedPlace.hasMatch(value) ||
        _wing.hasMatch(value) ||
        _blockOrTower.hasMatch(value) ||
        _floor.hasMatch(value) ||
        _streetAddress.hasMatch(value) ||
        _numberedStreet.hasMatch(value) ||
        _pinCode.hasMatch(value) ||
        _namedBuilding.hasMatch(value) ||
        _numberedSociety.hasMatch(value) ||
        _hasPlausibleCoordinates(_coordinatePair, value) ||
        _hasPlausibleCoordinates(_labeledCoordinates, value);
  }

  bool _hasPlausibleCoordinates(RegExp pattern, String value) {
    for (final match in pattern.allMatches(value)) {
      final latitude = double.tryParse(match.group(1) ?? '');
      final longitude = double.tryParse(match.group(2) ?? '');
      if (latitude != null &&
          longitude != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        return true;
      }
    }
    return false;
  }
}
