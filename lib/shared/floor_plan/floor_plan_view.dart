import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'floor_plan_data.dart';
import 'floor_plan_painter.dart';

/// Scales the schematic to fill the available width (crisp at any size) and,
/// for the incident route, drives the marching route + pulsing markers. Honors
/// the platform "remove animations" setting by holding a static frame.
class FloorPlanView extends StatefulWidget {
  const FloorPlanView({super.key, required this.mode});

  final FloorPlanMode mode;

  @override
  State<FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<FloorPlanView>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _animated => widget.mode == FloorPlanMode.incidentRoute;

  @override
  void initState() {
    super.initState();
    if (_animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller == null) return;
    if (MediaQuery.of(context).disableAnimations) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect =
        FloorPlan.designSize.width / FloorPlan.designSize.height;

    Widget paint(FloorPlanPainter painter) => ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: AspectRatio(
            aspectRatio: aspect,
            child: CustomPaint(painter: painter, size: Size.infinite),
          ),
        );

    final controller = _controller;
    if (controller == null) {
      return paint(FloorPlanPainter(mode: widget.mode));
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final reduce = MediaQuery.of(context).disableAnimations;
        final elapsed = controller.value * 3.0; // seconds
        return paint(
          FloorPlanPainter(
            mode: widget.mode,
            routePhase: reduce ? 0 : controller.value,
            firePulse: reduce
                ? 1
                : 0.5 - 0.5 * math.cos(2 * math.pi * (elapsed % 1.3) / 1.3),
            youPulse: reduce ? 0 : (elapsed % 1.8) / 1.8,
          ),
        );
      },
    );
  }
}
