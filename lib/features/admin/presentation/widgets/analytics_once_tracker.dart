import 'package:flutter/material.dart';

/// Widget mount olduğunda bir kez callback çağıran yardımcı.
class AnalyticsOnceTracker extends StatefulWidget {
  final VoidCallback onTrack;
  final Widget child;

  const AnalyticsOnceTracker({
    super.key,
    required this.onTrack,
    required this.child,
  });

  @override
  State<AnalyticsOnceTracker> createState() => _AnalyticsOnceTrackerState();
}

class _AnalyticsOnceTrackerState extends State<AnalyticsOnceTracker> {
  @override
  void initState() {
    super.initState();
    widget.onTrack();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
