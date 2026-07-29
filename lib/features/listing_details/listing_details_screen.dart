import 'package:flutter/material.dart';
import 'package:vihar_loop/core/accessibility/accessible_heading.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/listing_details/listing_details_view_model.dart';
import 'package:vihar_loop/features/listing_time_text.dart';

class ListingDetailsScreen extends StatefulWidget {
  const ListingDetailsScreen({
    required this.listing,
    required this.repository,
    required this.onListingChanged,
    super.key,
  });

  final Listing listing;
  final ListingRepository repository;
  final ValueChanged<Listing> onListingChanged;

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  late final ListingDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ListingDetailsViewModel(
      repository: widget.repository,
      initialListing: widget.listing,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final listing = _viewModel.listing;

        return PopScope<void>(
          canPop: !_viewModel.isActionRunning,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _viewModel.isActionRunning) {
              _showMessage('Finishing this update…');
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Listing details')),
            body: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _StateLabels(listing: listing),
                  const SizedBox(height: 16),
                  AccessibleHeading(
                    level: 1,
                    child: Text(
                      listing.title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    listing.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 28),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: listing.category.label,
                  ),
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Approximate area',
                    value: listing.approximateArea.label,
                  ),
                  _DetailRow(
                    icon: Icons.handshake_outlined,
                    label: 'Contact preference',
                    value: listing.contactPreference.label,
                  ),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: listing.kind.activeUntilLabel,
                    value: listingTimeText(context, listing),
                  ),
                  _DetailRow(
                    icon: listing.status == ListingStatus.open
                        ? Icons.radio_button_checked
                        : Icons.check_circle_outline,
                    label: 'Status',
                    value: listing.status.label,
                  ),
                  const Divider(height: 32),
                  AccessibleHeading(
                    level: 2,
                    child: Text(
                      'Your activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These markers are stored only on this device. '
                    'Marking contacted does not send a message.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    label:
                        listing.isSaved ? 'Remove from saved' : 'Save listing',
                    progressLabel: listing.isSaved ? 'Updating…' : 'Saving…',
                    icon: listing.isSaved
                        ? Icons.bookmark_remove_outlined
                        : Icons.bookmark_add_outlined,
                    toggled: listing.isSaved,
                    isPending:
                        _viewModel.pendingAction == ListingDetailsAction.saved,
                    enabled: !_viewModel.isActionRunning,
                    onPressed: () => _changeSaved(!listing.isSaved),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: listing.isContacted
                        ? 'Remove contacted mark'
                        : 'Mark as contacted',
                    progressLabel: 'Updating…',
                    icon: listing.isContacted
                        ? Icons.mark_chat_unread_outlined
                        : Icons.mark_chat_read_outlined,
                    toggled: listing.isContacted,
                    isPending: _viewModel.pendingAction ==
                        ListingDetailsAction.contacted,
                    enabled: !_viewModel.isActionRunning,
                    onPressed: () => _changeContacted(!listing.isContacted),
                  ),
                  if (_viewModel.canChangeStatus) ...[
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: listing.status == ListingStatus.open
                          ? 'Close listing'
                          : 'Reopen listing',
                      progressLabel: listing.status == ListingStatus.open
                          ? 'Closing…'
                          : 'Reopening…',
                      icon: listing.status == ListingStatus.open
                          ? Icons.cancel_outlined
                          : Icons.restart_alt,
                      isPending: _viewModel.pendingAction ==
                          ListingDetailsAction.status,
                      enabled: !_viewModel.isActionRunning,
                      onPressed: listing.status == ListingStatus.open
                          ? _confirmClose
                          : _reopen,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeSaved(bool value) async {
    await _runAction(
      operation: () => _viewModel.setSaved(value),
      successMessage: value ? 'Saved on this device.' : 'Removed from saved.',
    );
  }

  Future<void> _changeContacted(bool value) async {
    await _runAction(
      operation: () => _viewModel.setContacted(value),
      successMessage:
          value ? 'Marked as contacted.' : 'Contacted mark removed.',
    );
  }

  Future<void> _confirmClose() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Close this listing?'),
          content: const Text(
            'It will stay on this device and can be reopened later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep open'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Close listing'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _runAction(
        operation: () => _viewModel.setStatus(ListingStatus.closed),
        successMessage: 'Listing closed.',
      );
    }
  }

  Future<void> _reopen() async {
    await _runAction(
      operation: () => _viewModel.setStatus(ListingStatus.open),
      successMessage: 'Listing reopened.',
    );
  }

  Future<void> _runAction({
    required Future<bool> Function() operation,
    required String successMessage,
  }) async {
    final succeeded = await operation();
    if (!mounted) {
      return;
    }

    if (succeeded) {
      widget.onListingChanged(_viewModel.listing);
      _showMessage(successMessage);
      return;
    }

    final failureMessage = _viewModel.failureMessage;
    if (failureMessage != null) {
      _showMessage(failureMessage);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StateLabels extends StatelessWidget {
  const _StateLabels({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = [
      listing.kind.label,
      listing.status.label,
      if (listing.isSaved) 'Saved',
      if (listing.isContacted) 'Contacted',
      if (listing.origin == ListingOrigin.local) 'Your post',
    ].join('. ');

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(
                listing.kind == ListingKind.need
                    ? Icons.search
                    : Icons.volunteer_activism_outlined,
              ),
              label: Text(listing.kind.label),
            ),
            Chip(
              avatar: Icon(
                listing.status == ListingStatus.open
                    ? Icons.radio_button_checked
                    : Icons.check_circle_outline,
              ),
              label: Text(listing.status.label),
            ),
            if (listing.isSaved)
              const Chip(
                avatar: Icon(Icons.bookmark),
                label: Text('Saved'),
              ),
            if (listing.isContacted)
              const Chip(
                avatar: Icon(Icons.forum_outlined),
                label: Text('Contacted'),
              ),
            if (listing.origin == ListingOrigin.local)
              const Chip(
                avatar: Icon(Icons.person_outline),
                label: Text('Your post'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.progressLabel,
    required this.icon,
    required this.isPending,
    required this.enabled,
    required this.onPressed,
    this.toggled,
  });

  final String label;
  final String progressLabel;
  final IconData icon;
  final bool isPending;
  final bool enabled;
  final VoidCallback onPressed;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final visibleLabel = isPending ? progressLabel : label;
    final callback = enabled ? onPressed : null;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      toggled: toggled,
      liveRegion: isPending,
      label: visibleLabel,
      onTap: callback,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: callback,
            style: FilledButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
            icon: isPending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(visibleLabel),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Semantics(
        container: true,
        label: '$label, $value',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
