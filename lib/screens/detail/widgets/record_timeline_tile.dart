import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/event_model.dart';
import '../../../models/record_model.dart';

/// 详情页时间轴记录单项卡片
class RecordTimelineTile extends StatelessWidget {
  final EventModel event;
  final RecordModel record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordTimelineTile({
    super.key,
    required this.event,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDurationType = event.type == EventType.duration;
    final isOngoing = record.isOngoing;

    final startTimeStr = DateFormatter.formatTimestampTime(record.startTime);
    final endTimeStr = record.endTime != null
        ? DateFormatter.formatTimestampTime(record.endTime!)
        : (isOngoing ? '进行中' : '');

    final sevColor = record.severityLevel.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOngoing
              ? const Color(0xFFE91E63).withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.15),
          width: isOngoing ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：时间范围与严重度标签
            Row(
              children: [
                Icon(
                  isDurationType ? Icons.timelapse_rounded : Icons.check_circle_rounded,
                  size: 18,
                  color: isOngoing ? const Color(0xFFE91E63) : event.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDurationType
                        ? '$startTimeStr ~ $endTimeStr (${record.formattedDuration})'
                        : '$startTimeStr 打卡',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOngoing ? const Color(0xFFE91E63) : null,
                    ),
                  ),
                ),
                if (record.severity != null && record.severity! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sevColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '疼痛 ${record.severity}/10',
                      style: TextStyle(
                        color: sevColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 诱因列表展示
            if (record.triggers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '🎯 诱因:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  for (final trigger in record.triggers)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trigger,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],

            // 缓解方式展示
            if (record.reliefMethods.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '💊 缓解:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  for (final relief in record.reliefMethods)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        relief,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2E7D32)),
                      ),
                    ),
                ],
              ),
            ],

            // 数值展示 (非时段型或带有度量)
            if (!isDurationType && record.value != null) ...[
              const SizedBox(height: 6),
              Text(
                '记录数值: ${record.value} ${event.unit ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: event.color,
                ),
              ),
            ],

            // 备注内容
            if (record.remark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.remark,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
