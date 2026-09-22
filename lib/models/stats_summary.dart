import 'record_model.dart';
import '../core/utils/date_formatter.dart';

/// 事件统计数据摘要模型
class EventStatsSummary {
  final int totalCount;
  final int todayCount;
  final int last7DaysCount;
  final int totalDurationMinutes;
  final double avgDurationMinutes;
  final double avgSeverity;
  final Map<String, int> triggerFrequencies;
  final Map<String, int> reliefFrequencies;
  final RecordModel? latestRecord;
  final RecordModel? ongoingRecord;

  const EventStatsSummary({
    required this.totalCount,
    required this.todayCount,
    required this.last7DaysCount,
    required this.totalDurationMinutes,
    required this.avgDurationMinutes,
    required this.avgSeverity,
    required this.triggerFrequencies,
    required this.reliefFrequencies,
    this.latestRecord,
    this.ongoingRecord,
  });

  /// 格式化总时长
  String get formattedTotalDuration =>
      DateFormatter.formatDurationMinutes(totalDurationMinutes);

  /// 格式化平均时长
  String get formattedAvgDuration =>
      DateFormatter.formatDurationMinutes(avgDurationMinutes.round());

  /// 获取前 N 个高发诱因
  List<MapEntry<String, int>> getTopTriggers({int limit = 5}) {
    final list = triggerFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// 获取前 N 个最常用缓解手段
  List<MapEntry<String, int>> getTopReliefMethods({int limit = 5}) {
    final list = reliefFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// 空数据默认构造
  factory EventStatsSummary.empty() {
    return const EventStatsSummary(
      totalCount: 0,
      todayCount: 0,
      last7DaysCount: 0,
      totalDurationMinutes: 0,
      avgDurationMinutes: 0.0,
      avgSeverity: 0.0,
      triggerFrequencies: {},
      reliefFrequencies: {},
      latestRecord: null,
      ongoingRecord: null,
    );
  }
}
