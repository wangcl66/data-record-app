import '../models/record_model.dart';
import '../models/stats_summary.dart';
import '../services/local_storage_service.dart';

/// 记录数据持久化仓储
class RecordRepository {
  final LocalStorageService _storage = LocalStorageService.instance;

  String _getRecordFilePath(String eventId) => 'records/$eventId.json';

  /// 获取指定事件的所有记录列表 (按开始时间倒序排列)
  Future<List<RecordModel>> getRecordsByEventId(String eventId) async {
    final path = _getRecordFilePath(eventId);
    final json = await _storage.readJson(path);

    if (json == null || json['records'] == null) {
      // 若是偏头痛默认事件且无记录，初始化几条高质量示例数据展示 ECharts
      if (eventId == 'evt_migraine_default') {
        final sampleRecords = _createSampleMigraineRecords(eventId);
        await saveRecords(eventId, sampleRecords);
        return sampleRecords;
      }
      return [];
    }

    final list = json['records'] as List<dynamic>;
    final records = list
        .map((e) => RecordModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 按开始时间倒序排列
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  /// 保存某事件的所有记录
  Future<bool> saveRecords(String eventId, List<RecordModel> records) async {
    final path = _getRecordFilePath(eventId);
    final map = {
      'version': 1,
      'eventId': eventId,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'records': records.map((e) => e.toJson()).toList(),
    };
    return _storage.writeJson(path, map);
  }

  /// 添加单条记录
  Future<bool> addRecord(RecordModel record) async {
    final records = await getRecordsByEventId(record.eventId);
    records.insert(0, record);
    return saveRecords(record.eventId, records);
  }

  /// 更新单条记录
  Future<bool> updateRecord(RecordModel record) async {
    final records = await getRecordsByEventId(record.eventId);
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      return saveRecords(record.eventId, records);
    }
    return false;
  }

  /// 删除单条记录
  Future<bool> deleteRecord(String eventId, String recordId) async {
    final records = await getRecordsByEventId(eventId);
    records.removeWhere((r) => r.id == recordId);
    return saveRecords(eventId, records);
  }

  /// 计算某事件的统计数据看板
  Future<EventStatsSummary> calculateSummary(String eventId) async {
    final records = await getRecordsByEventId(eventId);
    if (records.isEmpty) {
      return EventStatsSummary.empty();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    int todayCount = 0;
    int last7DaysCount = 0;
    int totalDurationMinutes = 0;
    int durationRecordCount = 0;
    int totalSeverity = 0;
    int severityRecordCount = 0;

    final Map<String, int> triggerMap = {};
    final Map<String, int> reliefMap = {};
    RecordModel? ongoing;

    for (final r in records) {
      if (r.isOngoing) {
        ongoing = r;
      }
      if (r.startTime >= todayStart) {
        todayCount++;
      }
      if (r.startTime >= sevenDaysAgo) {
        last7DaysCount++;
      }

      final dur = r.effectiveDurationMinutes;
      if (dur > 0) {
        totalDurationMinutes += dur;
        durationRecordCount++;
      }

      if (r.severity != null && r.severity! > 0) {
        totalSeverity += r.severity!;
        severityRecordCount++;
      }

      for (final t in r.triggers) {
        if (t.trim().isNotEmpty) {
          triggerMap[t] = (triggerMap[t] ?? 0) + 1;
        }
      }

      for (final rel in r.reliefMethods) {
        if (rel.trim().isNotEmpty) {
          reliefMap[rel] = (reliefMap[rel] ?? 0) + 1;
        }
      }
    }

    final avgDur = durationRecordCount > 0
        ? totalDurationMinutes / durationRecordCount
        : 0.0;
    final avgSev = severityRecordCount > 0
        ? totalSeverity / severityRecordCount
        : 0.0;

    return EventStatsSummary(
      totalCount: records.length,
      todayCount: todayCount,
      last7DaysCount: last7DaysCount,
      totalDurationMinutes: totalDurationMinutes,
      avgDurationMinutes: avgDur,
      avgSeverity: avgSev,
      triggerFrequencies: triggerMap,
      reliefFrequencies: reliefMap,
      latestRecord: records.isNotEmpty ? records.first : null,
      ongoingRecord: ongoing,
    );
  }

  /// 创建示例偏头痛记录，便于快速可视化
  List<RecordModel> _createSampleMigraineRecords(String eventId) {
    final now = DateTime.now();
    return [
      RecordModel(
        id: 'rec_sample_1',
        eventId: eventId,
        startTime: now.subtract(const Duration(days: 1, hours: 5)).millisecondsSinceEpoch,
        endTime: now.subtract(const Duration(days: 1, hours: 2)).millisecondsSinceEpoch,
        durationMinutes: 180,
        severity: 8,
        triggers: ['昨晚熬夜', '咖啡因/饮浓茶'],
        reliefMethods: ['口服布洛芬 400mg', '暗室平躺冷敷'],
        value: 3.0,
        remark: '开会时右侧太阳穴剧烈跳痛，畏光畏声，服药后暗室休息缓解',
        tags: ['右侧跳痛', '畏光'],
        createdAt: now.subtract(const Duration(days: 1, hours: 5)).millisecondsSinceEpoch,
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)).millisecondsSinceEpoch,
      ),
      RecordModel(
        id: 'rec_sample_2',
        eventId: eventId,
        startTime: now.subtract(const Duration(days: 4, hours: 8)).millisecondsSinceEpoch,
        endTime: now.subtract(const Duration(days: 4, hours: 6)).millisecondsSinceEpoch,
        durationMinutes: 120,
        severity: 5,
        triggers: ['工作压力大', '强光刺激/长时间盯屏'],
        reliefMethods: ['对乙酰氨基酚', '闭目静养'],
        value: 2.0,
        remark: '连续写代码后额头胀痛，轻微恶心',
        tags: ['额头胀痛'],
        createdAt: now.subtract(const Duration(days: 4, hours: 8)).millisecondsSinceEpoch,
        updatedAt: now.subtract(const Duration(days: 4, hours: 6)).millisecondsSinceEpoch,
      ),
      RecordModel(
        id: 'rec_sample_3',
        eventId: eventId,
        startTime: now.subtract(const Duration(days: 9, hours: 4)).millisecondsSinceEpoch,
        endTime: now.subtract(const Duration(days: 9, hours: 0)).millisecondsSinceEpoch,
        durationMinutes: 240,
        severity: 9,
        triggers: ['天气剧变/受凉', '昨晚熬夜'],
        reliefMethods: ['口服布洛芬 400mg', '深度睡眠'],
        value: 4.0,
        remark: '降温阴雨天，起床即感到强烈搏动痛，卧床休息后睡醒好转',
        tags: ['全头胀痛', '卧床'],
        createdAt: now.subtract(const Duration(days: 9, hours: 4)).millisecondsSinceEpoch,
        updatedAt: now.subtract(const Duration(days: 9, hours: 0)).millisecondsSinceEpoch,
      ),
      RecordModel(
        id: 'rec_sample_4',
        eventId: eventId,
        startTime: now.subtract(const Duration(days: 15, hours: 3)).millisecondsSinceEpoch,
        endTime: now.subtract(const Duration(days: 15, hours: 1, minutes: 45)).millisecondsSinceEpoch,
        durationMinutes: 75,
        severity: 4,
        triggers: ['跳餐/低血糖'],
        reliefMethods: ['补充电解质温水', '闭目静养'],
        value: 1.25,
        remark: '中午没按时吃饭诱发轻微偏头痛，进食并饮水后缓解',
        tags: ['轻微'],
        createdAt: now.subtract(const Duration(days: 15, hours: 3)).millisecondsSinceEpoch,
        updatedAt: now.subtract(const Duration(days: 15, hours: 1, minutes: 45)).millisecondsSinceEpoch,
      ),
    ];
  }
}
