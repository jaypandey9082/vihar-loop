import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/neighborhood.dart';
import 'package:vihar_loop/features/feed/feed_view_model.dart';
import 'package:vihar_loop/features/feed/listing_card.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.repository,
    super.key,
  });

  final ListingRepository repository;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FeedViewModel(repository: widget.repository);
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
              FeedStatus.empty => const _EmptyFeed(),
              FeedStatus.failed => _ErrorFeed(
                  message: _viewModel.message ?? FeedViewModel.failureMessage,
                  onRetry: _viewModel.retry,
                ),
              FeedStatus.ready => _ReadyFeed(
                  viewModel: _viewModel,
                  onListingTap: _openDetails,
                ),
            };
          },
        ),
      ),
    );
  }

  void _openDetails(int index) {
    final listing = _viewModel.listings[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListingDetailsScreen(listing: listing),
      ),
    );
  }
}

class _ReadyFeed extends StatelessWidget {
  const _ReadyFeed({
    required this.viewModel,
    required this.onListingTap,
  });

  final FeedViewModel viewModel;
  final ValueChanged<int> onListingTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _FeedHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.separated(
            itemCount: viewModel.listings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return ListingCard(
                listing: viewModel.listings[index],
                onTap: () => onListingTap(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

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
        ],
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
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          container: true,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'No listings yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Be the first to post a need or offer in Vidyavihar.',
                textAlign: TextAlign.center,
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
