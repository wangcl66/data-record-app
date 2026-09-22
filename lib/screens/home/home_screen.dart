import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../widgets/ongoing_banner.dart';
import '../detail/event_detail_screen.dart';
import '../detail/widgets/record_form_sheet.dart';
import '../settings/backup_screen.dart';
import 'widgets/event_card_view.dart';
import 'widgets/event_form_dialog.dart';

/// 首页：事件任务看板
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = context.watch<EventProvider>();
    final ongoingEvents = eventProvider.ongoingEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('时迹'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_rounded),
            tooltip: '数据备份与导出',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.loadEvents(),
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchBar(
                leading: const Icon(Icons.search_rounded, size: 20),
                hintText: '搜索事件名称或描述...',
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(
                  theme.colorScheme.surfaceVariant.withOpacity(0.4),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => eventProvider.setSearchQuery(val),
              ),
            ),

            // 进行中发作/计时横幅 (若有)
            if (ongoingEvents.isNotEmpty) ...[
              for (final event in ongoingEvents)
                OngoingEventBanner(
                  event: event,
                  ongoingRecord: eventProvider.ongoingRecordMap[event.id]!,
                  onFinish: () => _handleFinishOngoing(context, event),
                ),
            ],

            // 事件列表 / 空状态
            Expanded(
              child: eventProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : eventProvider.events.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 88),
                          itemCount: eventProvider.events.length,
                          itemBuilder: (context, index) {
                            final event = eventProvider.events[index];
                            return EventCardView(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailScreen(event: event),
                                  ),
                                ).then((_) => eventProvider.loadEvents());
                              },
                              onEdit: () => _showEditDialog(context, event),
                              onDelete: () =>
                                  _showDeleteConfirm(context, event),
                              onStartOngoing: () =>
                                  eventProvider.startOngoingRecord(event.id),
                              onStopOngoing: () =>
                                  _handleFinishOngoing(context, event),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建事件'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '还没有任何记录事件',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方「新建事件」开始记录偏头痛规律、饮水打卡等',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('立即新建事件'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    showDialog(
      context: context,
      builder: (_) => EventFormDialog(
        onSave: (newEvent) => eventProvider.createEvent(newEvent),
      ),
    );
  }

  void _showEditDialog(BuildContext context, EventModel event) {
    final eventProvider = context.read<EventProvider>();
    showDialog(
      context: context,
      builder: (_) => EventFormDialog(
        initialEvent: event,
        onSave: (updatedEvent) => eventProvider.updateEvent(updatedEvent),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, EventModel event) {
    final eventProvider = context.read<EventProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确认删除事件?'),
        content: Text('删除「${event.name}」将同时清理其所有关联历史记录，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              eventProvider.deleteEvent(event.id);
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinishOngoing(
      BuildContext context, EventModel event) async {
    final eventProvider = context.read<EventProvider>();
    final stoppedRecord = await eventProvider.stopOngoingRecord(event.id);
    if (stoppedRecord != null && context.mounted) {
      // 弹出记录完善 BottomSheet，方便用户补充诱因、缓解药物与疼痛等级
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RecordFormSheet(
          event: event,
          initialRecord: stoppedRecord,
          onSave: (completedRecord) {
            // 保存完善后的记录
            eventProvider.loadEvents();
          },
        ),
      );
    }
  }
}
