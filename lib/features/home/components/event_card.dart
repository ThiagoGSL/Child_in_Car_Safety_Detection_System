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
    final Color pastColor = const Color(0xFF53BF9D); // Verde-água/ciano
    final Color notPastColor = const Color(0xFF16213E).withOpacity(0.7); // Azul escuro semitransparente

    return Container(
      margin: const EdgeInsets.only(left: 25, top: 15, bottom: 15, right: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // MODIFICAÇÃO: A cor de fundo será sempre a mesma.
        color: notPastColor,
        // MODIFICAÇÃO: A borda será adicionada condicionalmente.
        border: isPast 
          ? Border.all(color: pastColor, width: 2) // Borda verde se 'isPast' for true.
          : null, // Nenhuma borda caso contrário.
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}