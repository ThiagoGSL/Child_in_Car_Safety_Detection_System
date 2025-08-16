import 'package:app_v0/features/home/components/event_card.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class MyTimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final bool isActive;
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
    const Color primaryColor = Color(0xFF53A194);
    const Color textColor = Color(0xFF524F42);
    const Color inactiveColor = Color(0xFF524F42);

    return SizedBox(
      height: 110,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        beforeLineStyle: LineStyle(
          color: isPast ? primaryColor : inactiveColor.withOpacity(0.3),
          thickness: 2,
        ),
        indicatorStyle: IndicatorStyle(
          width: 30,
          height: 30,
          color:
              isPast
                  ? primaryColor
                  : (isActive ? textColor : inactiveColor.withOpacity(0.3)),
          iconStyle: IconStyle(
            color:
                isPast
                    ? Colors.white
                    : (isActive ? Colors.white : textColor.withOpacity(0.7)),
            iconData:
                isPast
                    ? Icons.check
                    : (isActive ? Icons.hdr_strong : Icons.circle_outlined),
            fontSize: 18,
          ),
          padding: const EdgeInsets.all(4),
        ),
        endChild: EventCard(isPast: isPast, child: eventCard),
      ),
    );
  }
}
