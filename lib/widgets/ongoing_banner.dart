import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';
import '../models/event_model.dart';
import '../models/record_model.dart';

/// 首页顶部正在发作/进行中事件提示横幅
class OngoingEventBanner extends StatefulWidget {
  final EventModel event;
  final RecordModel ongoingRecord;
  final VoidCallback onFinish;

  const OngoingEventBanner({
    super.key,
    required this.event,
    required this.ongoingRecord,
    required this.onFinish,
  });

  @override
  State<OngoingEventBanner> createState() => _OngoingEventBannerState();
}

class _OngoingEventBannerState extends State<OngoingEventBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - widget.ongoingRecord.startTime;
    final timerText = DateFormatter.formatTimerDuration(
      Duration(milliseconds: elapsedMs > 0 ? elapsedMs : 0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.event.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '发作中',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '已持续: $timerText',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onFinish,
            icon: const Icon(Icons.stop_circle_rounded, size: 18),
            label: const Text('结束发作'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(96, 40),
            ),
          ),
        ],
      ),
    );
  }
}
