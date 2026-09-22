import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/record_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/record_provider.dart';
import '../../widgets/echarts_view.dart';
import '../home/widgets/event_form_dialog.dart';
import 'widgets/record_form_sheet.dart';
import 'widgets/record_timeline_tile.dart';

/// 事件详情页：多维图表看板与时间轴记录列表
class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().initForEvent(_currentEvent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recordProvider = context.watch<RecordProvider>();
    final summary = recordProvider.statsSummary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentEvent.iconData, color: _currentEvent.color, size: 20),
            const SizedBox(width: 8),
            Text(_currentEvent.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑事件配置',
            onPressed: _showEditEventDialog,
          ),
        ],
      ),
      body: recordProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => recordProvider.initForEvent(_currentEvent),
              child: CustomScrollView(
                slivers: [
                  // 1. 统计看板卡片
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _buildSummaryDashboard(context, summary),
                    ),
                  ),

                  // 2. ECharts 多维可视化图表区
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 图表类型与时间范围切换栏
                          _buildChartControls(context, recordProvider),
                          const SizedBox(height: 10),

                          // ECharts 图表容器
                          EChartsContainer(
                            optionJson: recordProvider.getEChartsOption(isDark: isDark),
                            height: 250,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. 中段主操作栏
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildActionButtons(context, recordProvider),
                    ),
                  ),

                  // 4. 底部时间轴记录列表标题
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          Icon(Icons.timeline_rounded,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '历史记录时间轴 (${recordProvider.allRecords.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. 按天分组的历史记录时间轴
                  if (recordProvider.allRecords.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            '暂无记录数据，点击上方按钮新增',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTimelineSlivers(context, recordProvider),

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
    );
  }

  /// 统计指标概览看板
  Widget _buildSummaryDashboard(BuildContext context, summary) {
    final isDuration = _currentEvent.type == EventType.duration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentEvent.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _currentEvent.color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCol(
                context,
                title: '历史总计',
                value: '${summary.totalCount} 次',
              ),
              _buildDivider(),
              _buildStatCol(
                context,
                title: isDuration ? '近7日发作' : '今日打卡',
                value: isDuration
                    ? '${summary.last7DaysCount} 次'
                    : '${summary.todayCount} 次',
              ),
              if (isDuration) ...[
                _buildDivider(),
                _buildStatCol(
                  context,
                  title: '平均持续',
                  value: summary.formattedAvgDuration,
                ),
                if (_currentEvent.hasSeverity) ...[
                  _buildDivider(),
                  _buildStatCol(
                    context,
                    title: '平均疼痛',
                    value: summary.avgSeverity > 0
                        ? '${summary.avgSeverity.toStringAsFixed(1)}/10'
                        : '-',
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(BuildContext context,
      {required String title, required String value}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _currentEvent.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// 图表控制器 (模式切换 + 时间范围筛选)
  Widget _buildChartControls(
      BuildContext context, RecordProvider recordProvider) {
    final theme = Theme.of(context);
    final isDuration = _currentEvent.type == EventType.duration;

    return Column(
      children: [
        // 图表模式切换 (持续时长 / 24h时段 / 诱因排行)
        if (isDuration)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartMode.values.map((mode) {
                final isSelected = recordProvider.chartMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mode.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(mode.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => recordProvider.setChartMode(mode),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),

        // 时间范围筛选 (7天 / 30天 / 90天 / 全部)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: TimeRangeFilter.values.map((filter) {
            final isSelected = recordProvider.timeFilter == filter;
            return InkWell(
              onTap: () => recordProvider.setTimeFilter(filter),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 中段操作按钮
  Widget _buildActionButtons(
      BuildContext context, RecordProvider recordProvider) {
    final isDuration = _currentEvent.type == EventType.duration;
    final ongoing = recordProvider.statsSummary.ongoingRecord;

    if (isDuration) {
      if (ongoing != null) {
        return ElevatedButton.icon(
          onPressed: () => _handleFinishOngoing(context, ongoing),
          icon: const Icon(Icons.stop_circle_rounded),
          label: const Text('结束发作并完善诱因/缓解记录'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleStartOngoing,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('开始发作计时'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentEvent.color,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRecordForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('补录历史'),
              ),
            ),
          ],
        );
      }
    } else {
      return ElevatedButton.icon(
        onPressed: () => _showRecordForm(context),
        icon: const Icon(Icons.add_task_rounded),
        label: Text('+ 记录新发生 (${_currentEvent.name})'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentEvent.color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      );
    }
  }

  /// 按日期分组的时间轴 Sliver 列表
  List<Widget> _buildGroupedTimelineSlivers(
      BuildContext context, RecordProvider recordProvider) {
    final theme = Theme.of(context);
    final grouped = recordProvider.groupedRecords;
    final List<Widget> slivers = [];

    grouped.forEach((dateStr, records) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final record = records[index];
              return RecordTimelineTile(
                event: _currentEvent,
                record: record,
                onEdit: () => _showRecordForm(context, initialRecord: record),
                onDelete: () => _showDeleteRecordConfirm(context, record),
              );
            },
            childCount: records.length,
          ),
        ),
      );
    });

    return slivers;
  }

  void _showRecordForm(BuildContext context, {RecordModel? initialRecord}) {
    final recordProvider = context.read<RecordProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordFormSheet(
        event: _currentEvent,
        initialRecord: initialRecord,
        onSave: (record) => recordProvider.saveRecord(record),
      ),
    );
  }

  void _handleStartOngoing() async {
    final eventProvider = context.read<EventProvider>();
    final recordProvider = context.read<RecordProvider>();
    await eventProvider.startOngoingRecord(_currentEvent.id);
    await recordProvider.initForEvent(_currentEvent);
  }

  void _handleFinishOngoing(BuildContext context, RecordModel ongoing) async {
    final eventProvider = context.read<EventProvider>();
    final recordProvider = context.read<RecordProvider>();
    final stopped = await eventProvider.stopOngoingRecord(_currentEvent.id);
    if (stopped != null && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RecordFormSheet(
          event: _currentEvent,
          initialRecord: stopped,
          onSave: (record) async {
            await recordProvider.saveRecord(record);
            await eventProvider.loadEvents();
          },
        ),
      );
    }
  }

  void _showDeleteRecordConfirm(BuildContext context, RecordModel record) {
    final recordProvider = context.read<RecordProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确认删除记录?'),
        content: const Text('删除后该条记录及其诱因/缓解数据将无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              recordProvider.deleteRecord(record.id);
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

  void _showEditEventDialog() {
    final eventProvider = context.read<EventProvider>();
    final recordProvider = context.read<RecordProvider>();
    showDialog(
      context: context,
      builder: (_) => EventFormDialog(
        initialEvent: _currentEvent,
        onSave: (updated) async {
          await eventProvider.updateEvent(updated);
          setState(() {
            _currentEvent = updated;
          });
          await recordProvider.initForEvent(updated);
        },
      ),
    );
  }
}
