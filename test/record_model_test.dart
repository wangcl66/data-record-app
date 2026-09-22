import 'package:flutter_test/flutter_test.dart';
import 'package:data_record_app/models/event_model.dart';
import 'package:data_record_app/models/record_model.dart';
import 'package:data_record_app/core/utils/date_formatter.dart';

void main() {
  group('RecordModel 逻辑测试', () {
    test('持续时段计算与格式化', () {
      final now = DateTime(2026, 9, 20, 14, 15).millisecondsSinceEpoch;
      final end = DateTime(2026, 9, 20, 17, 30).millisecondsSinceEpoch; // 3小时15分 = 195分

      final record = RecordModel(
        id: 'test_rec_1',
        eventId: 'test_evt_1',
        startTime: now,
        endTime: end,
        durationMinutes: 195,
        severity: 8,
        triggers: ['昨晚熬夜', '咖啡因'],
        reliefMethods: ['口服布洛芬 400mg', '暗室冷敷'],
        createdAt: now,
        updatedAt: end,
      );

      expect(record.effectiveDurationMinutes, 195);
      expect(record.formattedDuration, '3小时15分');
      expect(record.severityLevel, SeverityLevel.severe);
      expect(record.triggers.length, 2);
      expect(record.reliefMethods.length, 2);
    });

    test('轻度及未评级疼痛等级映射', () {
      const mildRecord = RecordModel(
        id: 'rec_mild',
        eventId: 'evt_1',
        startTime: 1000,
        severity: 2,
        createdAt: 1000,
        updatedAt: 1000,
      );
      expect(mildRecord.severityLevel, SeverityLevel.mild);

      const unratedRecord = RecordModel(
        id: 'rec_unrated',
        eventId: 'evt_1',
        startTime: 1000,
        createdAt: 1000,
        updatedAt: 1000,
      );
      expect(unratedRecord.severityLevel, SeverityLevel.none);
    });

    test('DateFormatter 相对时间与格式化', () {
      final durationStr = DateFormatter.formatDurationMinutes(120);
      expect(durationStr, '2小时');

      final durationWithMins = DateFormatter.formatDurationMinutes(45);
      expect(durationWithMins, '45分钟');
    });

    test('EventModel 序列化与反序列化', () {
      const event = EventModel(
        id: 'evt_test',
        name: '偏头痛记录',
        type: EventType.duration,
        colorValue: 0xFFE91E63,
        hasSeverity: true,
        presetTriggers: ['熬夜', '压力'],
        presetReliefMethods: ['布洛芬', '冷敷'],
        createdAt: 1000000,
        updatedAt: 1000000,
      );

      final json = event.toJson();
      final fromJson = EventModel.fromJson(json);

      expect(fromJson.id, 'evt_test');
      expect(fromJson.name, '偏头痛记录');
      expect(fromJson.type, EventType.duration);
      expect(fromJson.hasSeverity, true);
      expect(fromJson.presetTriggers, ['熬夜', '压力']);
      expect(fromJson.presetReliefMethods, ['布洛芬', '冷敷']);
    });
  });
}
