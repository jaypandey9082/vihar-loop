import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';
import 'package:vihar_loop/features/create_listing/create_listing_screen.dart';
import 'package:vihar_loop/features/feed/feed_view_model.dart';
import 'package:vihar_loop/features/feed/listing_card.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.repository,
    this.clock = DateTime.now,
    super.key,
  });

  final ListingRepository repository;
  final Clock clock;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FeedViewModel(
      repository: widget.repository,
      clock: widget.clock,
    );
    unawaited(_viewModel.loadListings());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return switch (_viewModel.status) {
              FeedStatus.initial || FeedStatus.loading => const _LoadingFeed(),
              FeedStatus.empty => _EmptyFeed(onCreate: _openCreate),
              FeedStatus.failed => _ErrorFeed(
                  message: _viewModel.message ?? FeedViewModel.failureMessage,
                  onRetry: _viewModel.retry,
                ),
              FeedStatus.ready => _ReadyFeed(
                  viewModel: _viewModel,
                  onListingTap: _openDetails,
                  onCreate: _openCreate,
                ),
            };
          },
        ),
      ),
    );
  }

  Future<void> _openCreate() async {
    final listing = await Navigator.of(context).push<Listing>(
      MaterialPageRoute<Listing>(
        builder: (context) => CreateListingScreen(
          repository: widget.repository,
          clock: widget.clock,
        ),
      ),
    );
    if (!mounted || listing == null) {
      return;
    }
    if (_viewModel.addCreatedListing(listing)) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Listing posted on this device.')),
      );
    }
  }

  void _openDetails(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListingDetailsScreen(
          listing: listing,
          repository: widget.repository,
          onListingChanged: _viewModel.applyListingUpdate,
        ),
      ),
    );
  }
}

class _ReadyFeed extends StatelessWidget {
  const _ReadyFeed({
    required this.viewModel,
    required this.onListingTap,
    required this.onCreate,
  });

  final FeedViewModel viewModel;
  final ValueChanged<Listing> onListingTap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _FeedHeader(onCreate: onCreate)),
        SliverToBoxAdapter(child: _FeedFilters(viewModel: viewModel)),
        if (viewModel.visibleListings.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FilteredEmptyState(onClear: viewModel.clearFilters),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: viewModel.visibleListings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = viewModel.visibleListings[index];
                return ListingCard(
                  listing: listing,
                  timeBadge: viewModel.timeBadgeFor(listing),
                  onTap: () => onListingTap(listing),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ViharLoop',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${Neighborhood.vidyavihar.name}, '
                  '${Neighborhood.vidyavihar.city}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Nearby needs and offers',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A small local board for useful, time-sensitive exchanges around '
            'Vidyavihar—without sharing an exact address.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Post a need or offer'),
          ),
        ],
      ),
    );
  }
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({required this.viewModel});

  final FeedViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final visible = viewModel.visibleCount;
    final total = viewModel.totalCount;
    final countText = viewModel.hasActiveFilters
        ? '$visible of $total ${total == 1 ? 'listing' : 'listings'}'
        : '$total ${total == 1 ? 'listing' : 'listings'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in FeedKindFilter.values)
                ChoiceChip(
                  label: Text(switch (filter) {
                    FeedKindFilter.all => 'All',
                    FeedKindFilter.needs => 'Needs',
                    FeedKindFilter.offers => 'Offers',
                  }),
                  selected: viewModel.kindFilter == filter,
                  onSelected: (_) => viewModel.setKindFilter(filter),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Time', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in FeedTimeFilter.values)
                ChoiceChip(
                  label: Text(switch (filter) {
                    FeedTimeFilter.all => 'Any time',
                    FeedTimeFilter.today => 'Today',
                    FeedTimeFilter.endingSoon => 'Ending soon',
                  }),
                  selected: viewModel.timeFilter == filter,
                  onSelected: (_) => viewModel.setTimeFilter(filter),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(countText),
                ),
              ),
              if (viewModel.hasActiveFilters)
                TextButton(
                  onPressed: viewModel.clearFilters,
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'No listings match these filters',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another type or time.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading nearby listings',
        child: const ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading nearby listings…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No listings yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to post a need or offer in Vidyavihar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Post a need or offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  const _ErrorFeed({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_problem_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to load listings',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading listings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
