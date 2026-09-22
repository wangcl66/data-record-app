import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';
import '../models/event_model.dart';
import '../models/record_model.dart';
import '../models/stats_summary.dart';
import '../repositories/record_repository.dart';

/// 图表展示模式枚举
enum ChartMode {
  duration('持续时长趋势', Icons.show_chart_rounded),
  timeOfDay('24h时段分布', Icons.bubble_chart_rounded),
  triggers('诱因与缓解排行', Icons.bar_chart_rounded);

  final String label;
  final IconData icon;
  const ChartMode(this.label, this.icon);
}

/// 时间范围筛选枚举
enum TimeRangeFilter {
  last7Days('近7天', 7),
  last30Days('近30天', 30),
  last90Days('近90天', 90),
  all('全部', 0);

  final String label;
  final int days;
  const TimeRangeFilter(this.label, this.days);
}

/// 单个事件的记录与图表状态管理器
class RecordProvider extends ChangeNotifier {
  final RecordRepository _recordRepo = RecordRepository();

  EventModel? _event;
  List<RecordModel> _allRecords = [];
  bool _isLoading = false;

  ChartMode _chartMode = ChartMode.duration;
  TimeRangeFilter _timeFilter = TimeRangeFilter.last30Days;
  EventStatsSummary _statsSummary = EventStatsSummary.empty();

  EventModel? get event => _event;
  List<RecordModel> get allRecords => _allRecords;
  bool get isLoading => _isLoading;
  ChartMode get chartMode => _chartMode;
  TimeRangeFilter get timeFilter => _timeFilter;
  EventStatsSummary get statsSummary => _statsSummary;

  /// 根据时间范围过滤后的记录列表
  List<RecordModel> get filteredRecords {
    if (_timeFilter.days == 0) return _allRecords;
    final cutoff = DateTime.now()
        .subtract(Duration(days: _timeFilter.days))
        .millisecondsSinceEpoch;
    return _allRecords.where((r) => r.startTime >= cutoff).toList();
  }

  /// 按日期分组的时间轴数据 (Map<"2026-09-20", List<RecordModel>>)
  Map<String, List<RecordModel>> get groupedRecords {
    final Map<String, List<RecordModel>> map = {};
    for (final r in _allRecords) {
      final dateKey =
          DateFormatter.formatDate(DateTime.fromMillisecondsSinceEpoch(r.startTime));
      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(r);
    }
    return map;
  }

  /// 切换图表类型
  void setChartMode(ChartMode mode) {
    _chartMode = mode;
    notifyListeners();
  }

  /// 切换时间范围
  void setTimeFilter(TimeRangeFilter filter) {
    _timeFilter = filter;
    notifyListeners();
  }

  /// 绑定事件并加载其全部记录
  Future<void> initForEvent(EventModel event) async {
    _event = event;
    _isLoading = true;
    notifyListeners();

    try {
      _allRecords = await _recordRepo.getRecordsByEventId(event.id);
      _statsSummary = await _recordRepo.calculateSummary(event.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存/新建记录
  Future<void> saveRecord(RecordModel record) async {
    if (_event == null) return;
    final index = _allRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      await _recordRepo.updateRecord(record);
    } else {
      await _recordRepo.addRecord(record);
    }
    await _refreshData();
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    if (_event == null) return;
    await _recordRepo.deleteRecord(_event!.id, recordId);
    await _refreshData();
  }

  Future<void> _refreshData() async {
    if (_event == null) return;
    _allRecords = await _recordRepo.getRecordsByEventId(_event!.id);
    _statsSummary = await _recordRepo.calculateSummary(_event!.id);
    notifyListeners();
  }

  // ==========================================
  // ECharts Option 动态生成核心算法
  // ==========================================

  /// 生成当前图表模式对应的 ECharts Option JSON 字符串
  String getEChartsOption({bool isDark = false}) {
    switch (_chartMode) {
      case ChartMode.duration:
        return _buildDurationLineChartOption(isDark);
      case ChartMode.timeOfDay:
        return _buildTimeOfDayScatterOption(isDark);
      case ChartMode.triggers:
        return _buildTriggersBarChartOption(isDark);
    }
  }

  /// 1. 持续时长与严重度折线图 Option
  String _buildDurationLineChartOption(bool isDark) {
    final records = filteredRecords.where((r) => !r.isOngoing).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime)); // 正序

    final dates = <String>[];
    final seriesData = <Map<String, dynamic>>[];

    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.startTime);
      final dateStr = DateFormatter.formatMonthDay(dt);
      final fullDateStr = DateFormatter.formatDateTime(dt);
      dates.add(dateStr);

      final durHours = (r.effectiveDurationMinutes / 60.0);
      final durHoursRounded = (durHours * 10).round() / 10.0;

      seriesData.add({
        'value': _event?.type == EventType.duration
            ? durHoursRounded
            : (r.value ?? 1.0),
        'dateStr': fullDateStr,
        'durationStr': r.formattedDuration,
        'severity': r.severity ?? 0,
        'triggers': r.triggers,
        'relief': r.reliefMethods,
      });
    }

    final axisTextColor = isDark ? '#A0A0B0' : '#64748B';
    final splitLineColor = isDark ? '#2E2E3E' : '#F1F5F9';
    final isDuration = _event?.type == EventType.duration;
    final yAxisUnit = isDuration ? '小时' : (_event?.unit ?? '次');

    final option = {
      'backgroundColor': 'transparent',
      'animationDuration': 600,
      'tooltip': {
        'trigger': 'item',
        'backgroundColor': isDark ? 'rgba(30, 30, 46, 0.95)' : 'rgba(255, 255, 255, 0.95)',
        'borderColor': isDark ? '#444' : '#E2E8F0',
        'borderWidth': 1,
        'padding': 10,
        'textStyle': {'color': isDark ? '#FFF' : '#1E293B', 'fontSize': 12},
      },
      'grid': {
        'left': '12%',
        'right': '8%',
        'top': '18%',
        'bottom': '16%',
        'containLabel': true,
      },
      'xAxis': {
        'type': 'category',
        'data': dates.isNotEmpty ? dates : ['暂无数据'],
        'axisLine': {'lineStyle': {'color': axisTextColor}},
        'axisLabel': {'color': axisTextColor, 'fontSize': 11},
      },
      'yAxis': {
        'type': 'value',
        'name': '度量 ($yAxisUnit)',
        'nameTextStyle': {'color': axisTextColor, 'fontSize': 11},
        'axisLabel': {'color': axisTextColor, 'fontSize': 11},
        'splitLine': {
          'lineStyle': {'color': splitLineColor, 'type': 'dashed'}
        },
      },
      'series': [
        {
          'name': isDuration ? '持续时长' : '数值',
          'type': 'line',
          'smooth': true,
          'data': seriesData.isNotEmpty
              ? seriesData
              : [
                  {'value': 0}
                ],
          'lineStyle': {'width': 3, 'color': '#E91E63'},
          'itemStyle': {'color': '#E91E63'},
          'areaStyle': {
            'color': {
              'type': 'linear',
              'x': 0,
              'y': 0,
              'x2': 0,
              'y2': 1,
              'colorStops': [
                {'offset': 0, 'color': 'rgba(233, 30, 99, 0.35)'},
                {'offset': 1, 'color': 'rgba(233, 30, 99, 0.0)'}
              ]
            }
          }
        }
      ]
    };

    return jsonEncode(option);
  }

  /// 2. 24 小时发作时段散点分布图 Option
  String _buildTimeOfDayScatterOption(bool isDark) {
    final records = filteredRecords.where((r) => !r.isOngoing).toList();
    final scatterData = <List<dynamic>>[];

    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.startTime);
      final dateStr = DateFormatter.formatMonthDay(dt);
      final hourDecimal = dt.hour + (dt.minute / 60.0);
      scatterData.add([dateStr, (hourDecimal * 10).round() / 10.0, r.severity ?? 5]);
    }

    final axisTextColor = isDark ? '#A0A0B0' : '#64748B';
    final splitLineColor = isDark ? '#2E2E3E' : '#F1F5F9';

    final option = {
      'backgroundColor': 'transparent',
      'tooltip': {
        'trigger': 'item',
        'backgroundColor': isDark ? '#1E1E2E' : '#FFF',
        'textStyle': {'color': isDark ? '#FFF' : '#333'},
      },
      'grid': {
        'left': '10%',
        'right': '8%',
        'top': '18%',
        'bottom': '16%',
        'containLabel': true,
      },
      'xAxis': {
        'type': 'category',
        'axisLine': {'lineStyle': {'color': axisTextColor}},
        'axisLabel': {'color': axisTextColor},
      },
      'yAxis': {
        'type': 'value',
        'name': '时刻 (0-24时)',
        'min': 0,
        'max': 24,
        'interval': 4,
        'nameTextStyle': {'color': axisTextColor},
        'axisLabel': {'color': axisTextColor},
        'splitLine': {
          'lineStyle': {'color': splitLineColor, 'type': 'dashed'}
        },
      },
      'series': [
        {
          'name': '发作时刻',
          'type': 'scatter',
          'symbolSize': 14,
          'itemStyle': {'color': '#3F51B5'},
          'data': scatterData,
        }
      ]
    };

    return jsonEncode(option);
  }

  /// 3. 诱因与缓解手段排行条形图 Option
  String _buildTriggersBarChartOption(bool isDark) {
    final triggers = _statsSummary.getTopTriggers(limit: 5);
    final yLabels = triggers.map((e) => e.key).toList().reversed.toList();
    final values = triggers.map((e) => e.value).toList().reversed.toList();

    final axisTextColor = isDark ? '#A0A0B0' : '#64748B';
    final splitLineColor = isDark ? '#2E2E3E' : '#F1F5F9';

    final option = {
      'backgroundColor': 'transparent',
      'grid': {
        'left': '25%',
        'right': '10%',
        'top': '15%',
        'bottom': '15%',
      },
      'xAxis': {
        'type': 'value',
        'minInterval': 1,
        'axisLabel': {'color': axisTextColor},
        'splitLine': {
          'lineStyle': {'color': splitLineColor, 'type': 'dashed'}
        },
      },
      'yAxis': {
        'type': 'category',
        'data': yLabels.isNotEmpty ? yLabels : ['无诱因数据'],
        'axisLabel': {'color': axisTextColor, 'fontSize': 11},
      },
      'series': [
        {
          'name': '出现次数',
          'type': 'bar',
          'data': values.isNotEmpty ? values : [0],
          'barWidth': 16,
          'itemStyle': {
            'color': '#FF9800',
            'borderRadius': [0, 8, 8, 0],
          },
        }
      ]
    };

    return jsonEncode(option);
  }
}
