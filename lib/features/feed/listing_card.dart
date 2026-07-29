import 'package:flutter/material.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_timing.dart';
import 'package:vihar_loop/features/listing_time_text.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    required this.listing,
    required this.timeBadge,
    required this.onTap,
    super.key,
  });

  final Listing listing;
  final ListingTimeBadge timeBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = listingTimeText(context, listing);
    final semanticLabel = [
      listing.kind.label,
      listing.title,
      listing.category.label,
      listing.approximateArea.label,
      '${listing.kind.activeUntilLabel} $time',
      listing.status.label,
      if (timeBadge == ListingTimeBadge.endingSoon) 'Ending soon',
      if (timeBadge == ListingTimeBadge.today) 'Today',
      if (listing.isSaved) 'Saved',
      if (listing.isContacted) 'Contacted',
      if (listing.origin == ListingOrigin.local) 'Your post',
    ].join('. ');

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: semanticLabel,
      onTapHint: 'Open listing details',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Label(
                        icon: listing.kind == ListingKind.need
                            ? Icons.search
                            : Icons.volunteer_activism_outlined,
                        text: listing.kind.label,
                        emphasized: true,
                      ),
                      if (timeBadge == ListingTimeBadge.endingSoon)
                        const _Label(
                          icon: Icons.timer_outlined,
                          text: 'Ending soon',
                        )
                      else if (timeBadge == ListingTimeBadge.today)
                        const _Label(
                          icon: Icons.today_outlined,
                          text: 'Today',
                        ),
                      _Label(
                        icon: listing.status == ListingStatus.open
                            ? Icons.radio_button_checked
                            : Icons.check_circle_outline,
                        text: listing.status.label,
                      ),
                      if (listing.isSaved)
                        const _Label(
                          icon: Icons.bookmark,
                          text: 'Saved',
                        ),
                      if (listing.isContacted)
                        const _Label(
                          icon: Icons.forum_outlined,
                          text: 'Contacted',
                        ),
                      if (listing.origin == ListingOrigin.local)
                        const _Label(
                          icon: Icons.person_outline,
                          text: 'Your post',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _MetadataRow(
                    icon: Icons.category_outlined,
                    text: listing.category.label,
                  ),
                  const SizedBox(height: 8),
                  _MetadataRow(
                    icon: Icons.place_outlined,
                    text: listing.approximateArea.label,
                  ),
                  const SizedBox(height: 8),
                  _MetadataRow(
                    icon: Icons.schedule,
                    text: '${listing.kind.activeUntilLabel}: $time',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        emphasized ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        emphasized ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}
