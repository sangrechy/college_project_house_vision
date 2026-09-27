import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable Architectural HUD Telemetry Bar for Studio & Field screens.
/// Displays live simulated spatial orientation, LiDAR state, and BIM sync pulse.
class HudTelemetryBar extends StatefulWidget {
  final String siteTag;
  final String coordinates;
  final bool isLiDarActive;

  const HudTelemetryBar({
    super.key,
    this.siteTag = 'SECTOR 4A • STRUCTURAL',
    this.coordinates = '11°01\'24"N 76°58\'12"E',
    this.isLiDarActive = true,
  });

  @override
  State<HudTelemetryBar> createState() => _HudTelemetryBarState();
}

class _HudTelemetryBarState extends State<HudTelemetryBar> {
  int _heading = 342;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Simulate live compass micro-drift
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _heading = 340 + (DateTime.now().second % 6);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Pulse dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Site Tag
          Flexible(
            child: Text(
              widget.siteTag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Compass
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_outlined,
                size: 12,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 4),
              Text(
                '$_heading° NW',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          if (widget.isLiDarActive) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 10, color: AppColors.borderHighlight),
            const SizedBox(width: 8),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 12,
                  color: AppColors.success,
                ),
                SizedBox(width: 3),
                Text(
                  'LiDAR',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
