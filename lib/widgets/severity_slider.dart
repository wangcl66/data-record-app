import 'package:flutter/material.dart';

/// 1~10 级 VAS 疼痛/严重程度滑块组件 (UI/UX Pro Max 规范)
class SeveritySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const SeveritySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Color _getSeverityColor(int val) {
    if (val <= 3) return const Color(0xFF4CAF50); // 绿色
    if (val <= 6) return const Color(0xFFFF9800); // 橙色
    if (val <= 8) return const Color(0xFFE91E63); // 玫红
    return const Color(0xFFD32F2F); // 深红
  }

  String _getSeverityDesc(int val) {
    if (val <= 0) return '未评级';
    if (val <= 2) return '轻微隐痛 (几乎不影响正常生活)';
    if (val <= 4) return '轻中度疼痛 (有不适感，尚可工作学习)';
    if (val <= 6) return '中度疼痛 (明显影响注意力与活动)';
    if (val <= 8) return '剧烈疼痛 (伴随畏光恶心，难以正常工作)';
    return '极其剧烈 (卧床不起，剧烈搏动性跳痛)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getSeverityColor(value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                '疼痛 / 严重程度评分 (VAS)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value / 10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getSeverityDesc(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 6,
            ),
            child: Slider(
              value: value.toDouble().clamp(1.0, 10.0),
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (newVal) => onChanged(newVal.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 (轻微)', style: theme.textTheme.bodySmall),
                Text('5 (中度)', style: theme.textTheme.bodySmall),
                Text('10 (剧烈)', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
