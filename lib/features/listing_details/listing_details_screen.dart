import 'package:flutter/material.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/listing_time_text.dart';

class ListingDetailsScreen extends StatelessWidget {
  const ListingDetailsScreen({
    required this.listing,
    super.key,
  });

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing details')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Wrap(
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
              ],
            ),
            const SizedBox(height: 16),
            Text(
              listing.title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              listing.description,
              style: textTheme.bodyLarge?.copyWith(height: 1.5),
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
          ],
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
    );
  }
}
