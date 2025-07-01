import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final bool isPast;
  final Widget child;

  const EventCard({
    super.key,
    required this.isPast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // NOVO: Paleta de cores para o tema escuro
    final Color pastColor = const Color(0xFF53BF9D); // Um verde-água/ciano
    final Color notPastColor = const Color(0xFF16213E).withOpacity(0.7); // Um azul escuro e semitransparente

    return Container(
      margin: const EdgeInsets.only(left: 25, top: 15, bottom: 15, right: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPast ? pastColor : notPastColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}