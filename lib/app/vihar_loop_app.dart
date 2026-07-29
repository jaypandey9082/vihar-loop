import 'package:flutter/material.dart';
import 'package:vihar_loop/app/app_theme.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/features/feed/feed_screen.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

class ViharLoopApp extends StatelessWidget {
  const ViharLoopApp({
    required this.listingRepository,
    required this.localAiService,
    this.clock = DateTime.now,
    super.key,
  });

  final ListingRepository listingRepository;
  final LocalAiService localAiService;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViharLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: FeedScreen(
        repository: listingRepository,
        localAiService: localAiService,
        clock: clock,
      ),
    );
  }
}
