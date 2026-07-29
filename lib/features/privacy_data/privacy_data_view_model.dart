import 'package:flutter/foundation.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';

class PrivacyDataViewModel extends ChangeNotifier {
  PrivacyDataViewModel({required ListingRepository repository})
      : _repository = repository;

  static const resetFailureMessage = 'We couldn’t finish resetting local data. '
      'Try again before leaving this screen.';

  final ListingRepository _repository;
  bool _isResetting = false;
  String? _failureMessage;
  bool _disposed = false;

  bool get isResetting => _isResetting;
  String? get failureMessage => _failureMessage;

  Future<List<Listing>?> resetLocalData() async {
    if (_disposed || _isResetting) {
      return null;
    }

    _failureMessage = null;
    _isResetting = true;
    notifyListeners();

    try {
      return await _repository.resetLocalData();
    } on Object {
      if (!_disposed) {
        _failureMessage = resetFailureMessage;
      }
      return null;
    } finally {
      if (!_disposed) {
        _isResetting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
