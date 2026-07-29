import 'package:flutter/material.dart';
import 'package:vihar_loop/core/accessibility/accessible_heading.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_view_model.dart';

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({
    required this.repository,
    super.key,
  });

  final ListingRepository repository;

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  late final PrivacyDataViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PrivacyDataViewModel(repository: widget.repository);
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
        final resetting = _viewModel.isResetting;
        return PopScope<List<Listing>>(
          canPop: !resetting,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && resetting) {
              _showMessage('Finishing the local-data reset…');
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Privacy & data')),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ViharLoop works locally on this device. There is no '
                      'account, server, or analytics connection.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 28),
                    const _PrivacySection(
                      title: 'What stays on this device',
                      children: [
                        Text(
                          'Encrypted local records contain the listing title, '
                          'description, category, broad Vidyavihar area, '
                          'contact preference, deadline, Open or Closed state, '
                          'and Saved and Contacted markers.',
                        ),
                        Text(
                          'A contact preference is stored, but actual contact '
                          'details are not collected. Records remain until you '
                          'reset local data, clear app data, or uninstall.',
                        ),
                      ],
                    ),
                    const _PrivacySection(
                      title: 'What ViharLoop does not collect',
                      children: [
                        _PrivacyBullet('No account or password'),
                        _PrivacyBullet('No phone-number or email field'),
                        _PrivacyBullet(
                          'No exact-address or live-location field',
                        ),
                        _PrivacyBullet('No GPS permission'),
                        _PrivacyBullet('No images or payment details'),
                        _PrivacyBullet('No analytics or remote telemetry'),
                        _PrivacyBullet('No backend upload'),
                      ],
                    ),
                    const _PrivacySection(
                      title: 'How local protection works',
                      children: [
                        Text(
                          'Listings are encrypted on this device. The database '
                          'key is stored separately using platform secure '
                          'storage. Android backup and device transfer are '
                          'disabled for this local product slice.',
                        ),
                        Text(
                          'Encryption does not protect an unlocked, rooted, '
                          'compromised, or instrumented device while the app '
                          'is using the data.',
                        ),
                      ],
                    ),
                    _PrivacySection(
                      title: 'Reset local data',
                      children: [
                        const Text(
                          'This removes your posts, Saved and Contacted '
                          'markers, and local status changes. ViharLoop '
                          'deletes the encrypted database and its current key, '
                          'then restores only the fictional sample listings.',
                        ),
                        Text(
                          'This cannot be undone.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (_viewModel.failureMessage case final message?)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Semantics(
                          container: true,
                          liveRegion: resetting,
                          button: true,
                          enabled: !resetting,
                          label: resetting
                              ? 'Resetting local data'
                              : 'Reset local data',
                          onTap: resetting ? null : _confirmAndReset,
                          onTapHint:
                              resetting ? null : 'Open reset confirmation',
                          child: ExcludeSemantics(
                            child: FilledButton.icon(
                              key: const Key('reset-local-data-button'),
                              onPressed: resetting ? null : _confirmAndReset,
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                disabledBackgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.55),
                                disabledForegroundColor: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                              icon: resetting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                              label: Text(
                                resetting ? 'Resetting…' : 'Reset local data',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Reset local data?'),
          content: const Text(
            'This removes every listing and activity stored by ViharLoop on '
            'this device. Only the fictional sample listings will be restored '
            'with a new encryption key. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep data'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset local data'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final listings = await _viewModel.resetLocalData();
    if (!mounted || listings == null) {
      return;
    }
    Navigator.pop(context, listings);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleHeading(
            level: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PrivacyBullet extends StatelessWidget {
  const _PrivacyBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('•')),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
