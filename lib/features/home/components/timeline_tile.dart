import 'package:app_v0/features/home/components/event_card.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class MyTimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final bool isActive; // NOVO: para saber qual passo está ativo
  final Widget eventCard;

  const MyTimelineTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.isActive,
    required this.eventCard,
  });

  @override
  Widget build(BuildContext context) {
    // NOVO: Paleta de cores para os elementos da timeline
    final Color pastColor = const Color(0xFF53BF9D);
    final Color activeColor = const Color(0xFF0F3460);
    final Color inactiveColor = const Color(0xFF16213E);

    return SizedBox(
      height: 110, // Altura ajustada
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        // Decoração da linha
        beforeLineStyle: LineStyle(
          color: isPast ? pastColor : inactiveColor,
          thickness: 2,
        ),
        // Decoração do indicador (a bolinha)
        indicatorStyle: IndicatorStyle(
          width: 30,
          height: 30,
          // Cor do indicador muda com o estado
          color: isPast ? pastColor : (isActive ? activeColor : inactiveColor),
          // Ícone dentro do indicador
          iconStyle: IconStyle(
            color: Colors.white,
            iconData: isPast ? Icons.check : (isActive ? Icons.hdr_strong : Icons.circle_outlined),
            fontSize: 18,
          ),
          padding: const EdgeInsets.all(4),
        ),
        endChild: EventCard(
          isPast: isPast,
          child: eventCard,
        ),
      ),
    );
  }
}