import 'package:flutter/foundation.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';

enum ListingDetailsAction { saved, contacted, status }

class ListingDetailsViewModel extends ChangeNotifier {
  ListingDetailsViewModel({
    required ListingRepository repository,
    required Listing initialListing,
  })  : _repository = repository,
        _listing = initialListing;

  static const savedFailureMessage =
      'We couldn’t update the saved state. Try again.';
  static const contactedFailureMessage =
      'We couldn’t update the contacted marker. Try again.';
  static const statusFailureMessage =
      'We couldn’t update this listing’s status. Try again.';

  final ListingRepository _repository;

  Listing _listing;
  ListingDetailsAction? _pendingAction;
  String? _failureMessage;
  bool _disposed = false;

  Listing get listing => _listing;
  ListingDetailsAction? get pendingAction => _pendingAction;
  bool get isActionRunning => _pendingAction != null;
  bool get canChangeStatus => _listing.origin == ListingOrigin.local;
  String? get failureMessage => _failureMessage;

  Future<bool> setSaved(bool value) {
    return _runAction(
      action: ListingDetailsAction.saved,
      failureMessage: savedFailureMessage,
      mutation: () => _repository.setSaved(
        listingId: _listing.id,
        isSaved: value,
      ),
    );
  }

  Future<bool> setContacted(bool value) {
    return _runAction(
      action: ListingDetailsAction.contacted,
      failureMessage: contactedFailureMessage,
      mutation: () => _repository.setContacted(
        listingId: _listing.id,
        isContacted: value,
      ),
    );
  }

  Future<bool> setStatus(ListingStatus value) {
    if (!canChangeStatus) {
      return Future<bool>.value(false);
    }
    return _runAction(
      action: ListingDetailsAction.status,
      failureMessage: statusFailureMessage,
      mutation: () => _repository.setStatus(
        listingId: _listing.id,
        status: value,
      ),
    );
  }

  Future<bool> _runAction({
    required ListingDetailsAction action,
    required String failureMessage,
    required Future<Listing> Function() mutation,
  }) async {
    if (_disposed || isActionRunning) {
      return false;
    }

    _failureMessage = null;
    _pendingAction = action;
    notifyListeners();

    try {
      final persisted = await mutation();
      if (_disposed) {
        return false;
      }
      _listing = persisted;
      return true;
    } on Object {
      if (_disposed) {
        return false;
      }
      _failureMessage = failureMessage;
      return false;
    } finally {
      if (!_disposed) {
        _pendingAction = null;
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
