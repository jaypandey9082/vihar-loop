import 'package:flutter/widgets.dart';

class AccessibleHeading extends StatelessWidget {
  const AccessibleHeading({
    required this.level,
    required this.child,
    super.key,
  }) : assert(level >= 1 && level <= 6);

  final int level;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Flutter 3.44 uses header on mobile; headingLevel supports newer engines.
      header: true,
      headingLevel: level,
      child: child,
    );
  }
}
