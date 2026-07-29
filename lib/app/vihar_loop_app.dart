import 'package:flutter/material.dart';
import 'package:vihar_loop/app/app_theme.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/features/feed/feed_screen.dart';

class ViharLoopApp extends StatelessWidget {
  const ViharLoopApp({
    required this.listingRepository,
    this.clock = DateTime.now,
    super.key,
  });

  final ListingRepository listingRepository;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViharLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: FeedScreen(repository: listingRepository, clock: clock),
    );
  }
}
