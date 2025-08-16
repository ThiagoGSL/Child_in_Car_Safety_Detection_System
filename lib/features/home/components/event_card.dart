import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final bool isPast;
  final Widget child;

  const EventCard({super.key, required this.isPast, required this.child});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF53A194);
    const Color inactiveColor = Color(0xFF524F42);

    return Container(
      margin: const EdgeInsets.only(left: 25, top: 10, bottom: 12, right: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPast ? primaryColor : inactiveColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: child,
    );
  }
}
