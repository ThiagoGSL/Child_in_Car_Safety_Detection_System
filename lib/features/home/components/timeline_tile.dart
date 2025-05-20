import 'package:app_v0/features/home/components/event_card.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class MyTimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final eventCard;
  const MyTimelineTile({
    super.key, 
    required this.isFirst, 
    required this.isLast, 
    required this.isPast,
    required this.eventCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
      
      // decorate the lines
      beforeLineStyle: LineStyle(
        color: isPast ? Colors.blue : Colors.blue.shade200),
      indicatorStyle: IndicatorStyle(
        width:35, 
        color: isPast ? Colors.blue: Colors.blue.shade200,
        iconStyle: IconStyle(
          iconData: Icons.done,
          color: isPast ? Colors.white : Colors.blue.shade200,
          )
        ),
        // event card
        endChild: EventCard(
          isPast: isPast,
          child: eventCard,
        ),
      ),
    );
  }
}