import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';

/// 首页事件任务卡片
class EventCardView extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStartOngoing;
  final VoidCallback onStopOngoing;

  const EventCardView({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStartOngoing,
    required this.onStopOngoing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = context.watch<EventProvider>();

    final count = eventProvider.recordCountMap[event.id] ?? 0;
    final latestRecord = eventProvider.latestRecordMap[event.id];
    final ongoingRecord = eventProvider.ongoingRecordMap[event.id];
    final isOngoing = ongoingRecord != null;

    final isDurationType = event.type == EventType.duration;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：图标、名称、类型徽章与操作菜单
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(event.iconData, color: event.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                event.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDurationType
                                    ? const Color(0xFFE91E63).withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.type.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDurationType
                                      ? const Color(0xFFE91E63)
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            event.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('编辑事件'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除事件', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 中部统计概览
              Row(
                children: [
                  _buildStatBadge(
                    context,
                    label: '历史总计',
                    value: '$count 次',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatBadge(
                    context,
                    label: '最近记录',
                    value: latestRecord != null
                        ? DateFormatter.getRelativeTime(latestRecord.startTime)
                        : '暂无记录',
                    icon: Icons.access_time_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 底部快捷操作条
              Row(
                children: [
                  if (isDurationType) ...[
                    if (isOngoing)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onStopOngoing,
                          icon: const Icon(Icons.stop_circle_rounded, size: 18),
                          label: const Text('结束发作并完善记录'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onStartOngoing,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('开始发作计时'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE91E63),
                            side: const BorderSide(color: Color(0xFFE91E63)),
                          ),
                        ),
                      ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => eventProvider.addQuickRecord(event),
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: Text(
                          event.unit != null
                              ? '+ 快速打卡 (${event.defaultValue?.toInt() ?? 1}${event.unit})'
                              : '+ 快速打卡',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
