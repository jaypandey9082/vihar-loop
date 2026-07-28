import 'package:flutter/material.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/data/in_memory_listing_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = InMemoryListingRepository();
  runApp(ViharLoopApp(listingRepository: repository));
}
