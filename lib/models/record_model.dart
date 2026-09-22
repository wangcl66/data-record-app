import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';

/// 严重程度/疼痛等级枚举与辅助工具
enum SeverityLevel {
  none(0, '无', Color(0xFF9E9E9E)),
  mild(1, '轻度 (可耐受)', Color(0xFF4CAF50)),
  moderate(2, '中度 (影响活动)', Color(0xFFFF9800)),
  severe(3, '重度 (卧床/剧烈)', Color(0xFFE91E63));

  final int code;
  final String label;
  final Color color;
  const SeverityLevel(this.code, this.label, this.color);

  static SeverityLevel fromValue(int? val) {
    if (val == null || val <= 0) return SeverityLevel.none;
    if (val <= 3) return SeverityLevel.mild;
    if (val <= 6) return SeverityLevel.moderate;
    return SeverityLevel.severe;
  }
}

/// 事件发生记录实体模型
class RecordModel {
  final String id;
  final String eventId;

  // 时间维度
  final int startTime; // 开始时间戳 (毫秒)
  final int? endTime; // 结束时间戳 (毫秒，为 null 且 isOngoing=true 表示进行中)
  final int? durationMinutes; // 持续分钟数
  final bool isOngoing; // 是否处于进行中状态

  // 症状与多维特征 (偏头痛/生活事件追踪)
  final int? severity; // 严重度/疼痛评分 (1 - 10)
  final List<String> triggers; // 发病诱因 (如: 熬夜, 咖啡因, 工作压力)
  final List<String> reliefMethods; // 缓解方式 (如: 布洛芬400mg, 暗室冷敷)

  // 基础量化与描述
  final double? value; // 数值指标 (如 3.25h 或 300ml)
  final String remark; // 详细备注/伴随症状
  final List<String> tags; // 自定义补充标签
  final int createdAt;
  final int updatedAt;

  const RecordModel({
    required this.id,
    required this.eventId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.isOngoing = false,
    this.severity,
    this.triggers = const [],
    this.reliefMethods = const [],
    this.value,
    this.remark = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 获取计算后的持续分钟数
  int get effectiveDurationMinutes {
    if (durationMinutes != null && durationMinutes! > 0) {
      return durationMinutes!;
    }
    if (endTime != null && endTime! >= startTime) {
      return ((endTime! - startTime) / 60000).round();
    }
    return 0;
  }

  /// 格式化持续时长字符串 (如: "3小时15分")
  String get formattedDuration {
    if (isOngoing) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      final mins = (elapsed / 60000).round();
      return '进行中 (${DateFormatter.formatDurationMinutes(mins)})';
    }
    return DateFormatter.formatDurationMinutes(effectiveDurationMinutes);
  }

  /// 获取严重度级别
  SeverityLevel get severityLevel => SeverityLevel.fromValue(severity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isOngoing': isOngoing,
      'severity': severity,
      'triggers': triggers,
      'reliefMethods': reliefMethods,
      'value': value,
      'remark': remark,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    return RecordModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      startTime: json['startTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      endTime: json['endTime'] as int?,
      durationMinutes: json['durationMinutes'] as int?,
      isOngoing: json['isOngoing'] as bool? ?? false,
      severity: json['severity'] as int?,
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reliefMethods: (json['reliefMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      value: (json['value'] as num?)?.toDouble(),
      remark: json['remark'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  RecordModel copyWith({
    String? id,
    String? eventId,
    int? startTime,
    int? endTime,
    int? durationMinutes,
    bool? isOngoing,
    int? severity,
    List<String>? triggers,
    List<String>? reliefMethods,
    double? value,
    String? remark,
    List<String>? tags,
    int? createdAt,
    int? updatedAt,
  }) {
    return RecordModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isOngoing: isOngoing ?? this.isOngoing,
      severity: severity ?? this.severity,
      triggers: triggers ?? this.triggers,
      reliefMethods: reliefMethods ?? this.reliefMethods,
      value: value ?? this.value,
      remark: remark ?? this.remark,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
