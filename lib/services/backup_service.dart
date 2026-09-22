import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';
import '../models/record_model.dart';
import '../repositories/event_repository.dart';
import '../repositories/record_repository.dart';

/// 数据本地备份与恢复服务
class BackupService {
  final EventRepository _eventRepo = EventRepository();
  final RecordRepository _recordRepo = RecordRepository();

  /// 导出完整数据为 JSON 字符串
  Future<String> exportBackupJson() async {
    final events = await _eventRepo.getAllEvents();
    final Map<String, dynamic> recordsMap = {};

    for (final event in events) {
      final records = await _recordRepo.getRecordsByEventId(event.id);
      recordsMap[event.id] = records.map((r) => r.toJson()).toList();
    }

    final backupData = {
      'app': 'DataRecordApp',
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'events': events.map((e) => e.toJson()).toList(),
      'records': recordsMap,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  /// 将备份导出到本地文件，返回文件绝对路径
  Future<String?> exportBackupToFile() async {
    try {
      final jsonString = await exportBackupJson();
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final file = File('${tempDir.path}/data_record_backup_$timestamp.json');
      await file.writeAsString(jsonString, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('导出备份文件失败: $e');
      return null;
    }
  }

  /// 从 JSON 字符串恢复数据 (覆盖式还原)
  Future<bool> restoreFromBackupJson(String jsonString) async {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      if (map['events'] == null) return false;

      // 还原事件
      final eventsList = (map['events'] as List<dynamic>)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _eventRepo.saveEvents(eventsList);

      // 还原各事件的记录
      if (map['records'] != null && map['records'] is Map<String, dynamic>) {
        final recordsMap = map['records'] as Map<String, dynamic>;
        for (final entry in recordsMap.entries) {
          final eventId = entry.key;
          final recordsList = (entry.value as List<dynamic>)
              .map((r) => RecordModel.fromJson(r as Map<String, dynamic>))
              .toList();
          await _recordRepo.saveRecords(eventId, recordsList);
        }
      }
      return true;
    } catch (e) {
      debugPrint('还原备份数据失败: $e');
      return false;
    }
  }
}
