import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/record_model.dart';
import '../repositories/event_repository.dart';
import '../repositories/record_repository.dart';

/// 全局事件任务状态管理器
class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepo = EventRepository();
  final RecordRepository _recordRepo = RecordRepository();

  List<EventModel> _events = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // 记录所有事件的最新状态及进行中的记录
  final Map<String, RecordModel?> _ongoingRecordMap = {};
  final Map<String, RecordModel?> _latestRecordMap = {};
  final Map<String, int> _recordCountMap = {};

  Timer? _timer; // 全局计时器驱动进行中状态刷新

  List<EventModel> get events {
    if (_searchQuery.trim().isEmpty) return _events;
    return _events
        .where((e) =>
            e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Map<String, RecordModel?> get ongoingRecordMap => _ongoingRecordMap;
  Map<String, RecordModel?> get latestRecordMap => _latestRecordMap;
  Map<String, int> get recordCountMap => _recordCountMap;

  /// 获取当前所有处于进行中发作/时段的事件列表
  List<EventModel> get ongoingEvents {
    return _events.where((e) => _ongoingRecordMap[e.id] != null).toList();
  }

  EventProvider() {
    _startTimer();
    loadEvents();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ongoingRecordMap.values.any((r) => r != null)) {
        notifyListeners(); // 驱动进行中秒数刷新
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 加载所有事件及状态
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await _eventRepo.getAllEvents();
      await _refreshAllEventMetadata();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新所有事件的最新记录与进行中状态
  Future<void> _refreshAllEventMetadata() async {
    for (final event in _events) {
      final records = await _recordRepo.getRecordsByEventId(event.id);
      _recordCountMap[event.id] = records.length;
      _latestRecordMap[event.id] = records.isNotEmpty ? records.first : null;
      _ongoingRecordMap[event.id] =
          records.where((r) => r.isOngoing).firstOrNull;
    }
    notifyListeners();
  }

  /// 新建事件
  Future<bool> createEvent(EventModel event) async {
    final success = await _eventRepo.addEvent(event);
    if (success) {
      await loadEvents();
    }
    return success;
  }

  /// 更新事件
  Future<bool> updateEvent(EventModel event) async {
    final success = await _eventRepo.updateEvent(event);
    if (success) {
      await loadEvents();
    }
    return success;
  }

  /// 删除事件
  Future<bool> deleteEvent(String eventId) async {
    final success = await _eventRepo.deleteEvent(eventId);
    if (success) {
      _ongoingRecordMap.remove(eventId);
      _latestRecordMap.remove(eventId);
      _recordCountMap.remove(eventId);
      await loadEvents();
    }
    return success;
  }

  /// 快速打卡 (瞬时事件)
  Future<void> addQuickRecord(EventModel event) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = RecordModel(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      eventId: event.id,
      startTime: now,
      endTime: now,
      durationMinutes: 0,
      value: event.defaultValue ?? 1.0,
      remark: '快捷打卡',
      createdAt: now,
      updatedAt: now,
    );
    await _recordRepo.addRecord(record);
    await _refreshAllEventMetadata();
  }

  /// 开始发作 / 开启进行中时段
  Future<RecordModel> startOngoingRecord(String eventId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = RecordModel(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      eventId: eventId,
      startTime: now,
      isOngoing: true,
      createdAt: now,
      updatedAt: now,
    );
    await _recordRepo.addRecord(record);
    await _refreshAllEventMetadata();
    return record;
  }

  /// 结束发作 / 完成进行中时段
  Future<RecordModel?> stopOngoingRecord(String eventId) async {
    final ongoing = _ongoingRecordMap[eventId];
    if (ongoing == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMins = ((now - ongoing.startTime) / 60000).round();
    final updated = ongoing.copyWith(
      endTime: now,
      durationMinutes: durationMins,
      isOngoing: false,
      updatedAt: now,
    );

    await _recordRepo.updateRecord(updated);
    await _refreshAllEventMetadata();
    return updated;
  }
}
