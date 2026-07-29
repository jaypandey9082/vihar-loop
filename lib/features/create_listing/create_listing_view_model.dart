import 'package:flutter/foundation.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';

class CreateListingViewModel extends ChangeNotifier {
  CreateListingViewModel({required ListingRepository repository})
      : _repository = repository;

  static const createFailureMessage =
      'We couldn’t post this listing. Your draft is still here, '
      'so you can try again.';

  final ListingRepository _repository;
  bool _isSubmitting = false;
  String? _failureMessage;
  bool _disposed = false;

  bool get isSubmitting => _isSubmitting;
  String? get failureMessage => _failureMessage;

  Future<Listing?> create(ListingDraft draft) async {
    if (_disposed || _isSubmitting) {
      return null;
    }

    _failureMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      return await _repository.createListing(draft);
    } on Object {
      if (!_disposed) {
        _failureMessage = createFailureMessage;
      }
      return null;
    } finally {
      if (!_disposed) {
        _isSubmitting = false;
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
