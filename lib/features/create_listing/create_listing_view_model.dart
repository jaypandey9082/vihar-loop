import 'package:flutter/foundation.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

enum CreateListingPendingAction { suggesting, submitting }

class CreateListingViewModel extends ChangeNotifier {
  CreateListingViewModel({
    required ListingRepository repository,
    required LocalAiService localAiService,
  })  : _repository = repository,
        _localAiService = localAiService;

  static const createFailureMessage =
      'We couldn’t post this listing. Your draft is still here, '
      'so you can try again.';
  static const suggestionFailureCopy =
      'We couldn’t suggest details. You can keep filling the form yourself.';

  final ListingRepository _repository;
  final LocalAiService _localAiService;
  CreateListingPendingAction? _pendingAction;
  ListingSuggestion? _suggestion;
  String? _suggestionFailureMessage;
  String? _failureMessage;
  bool _disposed = false;

  CreateListingPendingAction? get pendingAction => _pendingAction;
  bool get isSuggesting =>
      _pendingAction == CreateListingPendingAction.suggesting;
  bool get isSubmitting =>
      _pendingAction == CreateListingPendingAction.submitting;
  bool get isBusy => _pendingAction != null;
  ListingSuggestion? get suggestion => _suggestion;
  String? get suggestionFailureMessage => _suggestionFailureMessage;
  String? get failureMessage => _failureMessage;

  Future<ListingSuggestion?> suggestListing({
    required String description,
    required ListingKind preferredKind,
  }) async {
    if (_disposed || isBusy) {
      return null;
    }

    _suggestion = null;
    _suggestionFailureMessage = null;
    _pendingAction = CreateListingPendingAction.suggesting;
    notifyListeners();

    try {
      final suggestion = await _localAiService.suggestListing(
        description: description,
        preferredKind: preferredKind,
      );
      if (_disposed) {
        return null;
      }
      _suggestion = suggestion;
      return suggestion;
    } on Object {
      if (!_disposed) {
        _suggestionFailureMessage = suggestionFailureCopy;
      }
      return null;
    } finally {
      if (!_disposed) {
        _pendingAction = null;
        notifyListeners();
      }
    }
  }

  void dismissSuggestion() {
    if (_disposed ||
        (_suggestion == null && _suggestionFailureMessage == null)) {
      return;
    }
    _suggestion = null;
    _suggestionFailureMessage = null;
    notifyListeners();
  }

  Future<Listing?> create(ListingDraft draft) async {
    if (_disposed || isBusy) {
      return null;
    }

    _failureMessage = null;
    _pendingAction = CreateListingPendingAction.submitting;
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
