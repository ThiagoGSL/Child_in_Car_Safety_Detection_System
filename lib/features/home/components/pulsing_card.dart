import 'package:flutter/material.dart';

class PulsingCard extends StatefulWidget {
  final Widget child;
  final bool isPulsing;

  const PulsingCard({
    super.key,
    required this.child,
    required this.isPulsing,
  });

  @override
  State<PulsingCard> createState() => _PulsingCardState();
}

class _PulsingCardState extends State<PulsingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 1.0; // Reseta a opacidade para o valor completo
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}