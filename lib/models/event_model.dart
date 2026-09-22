import 'package:flutter/material.dart';

/// 事件记录模式
enum EventType {
  /// 瞬时发生型 (如喝水、服药、记灵感、体重)
  instant,

  /// 持续时段/症状发作型 (如偏头痛、睡眠、运动、设备故障)
  duration;

  String get label {
    switch (this) {
      case EventType.instant:
        return '单点打卡型';
      case EventType.duration:
        return '时段/症状型';
    }
  }

  String get description {
    switch (this) {
      case EventType.instant:
        return '记录某个时刻发生的事情（如喝水、服药）';
      case EventType.duration:
        return '记录有开始、结束、持续时间及诱因/缓解手段的事件（如偏头痛、睡眠）';
    }
  }
}

/// 事件任务实体模型
class EventModel {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final int iconCodePoint;
  final int colorValue;
  final String? unit;
  final double? defaultValue;
  final bool hasSeverity;
  final List<String> presetTriggers;
  final List<String> presetReliefMethods;
  final int createdAt;
  final int updatedAt;

  const EventModel({
    required this.id,
    required this.name,
    this.description = '',
    this.type = EventType.instant,
    this.iconCodePoint = 0xe1d7, // Icons.event_note_rounded 对应默认值
    this.colorValue = 0xFF3F51B5,
    this.unit,
    this.defaultValue,
    this.hasSeverity = false,
    this.presetTriggers = const [],
    this.presetReliefMethods = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  IconData get iconData => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'unit': unit,
      'defaultValue': defaultValue,
      'hasSeverity': hasSeverity,
      'presetTriggers': presetTriggers,
      'presetReliefMethods': presetReliefMethods,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.instant,
      ),
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe1d7,
      colorValue: json['colorValue'] as int? ?? 0xFF3F51B5,
      unit: json['unit'] as String?,
      defaultValue: (json['defaultValue'] as num?)?.toDouble(),
      hasSeverity: json['hasSeverity'] as bool? ?? false,
      presetTriggers: (json['presetTriggers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      presetReliefMethods: (json['presetReliefMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  EventModel copyWith({
    String? id,
    String? name,
    String? description,
    EventType? type,
    int? iconCodePoint,
    int? colorValue,
    String? unit,
    double? defaultValue,
    bool? hasSeverity,
    List<String>? presetTriggers,
    List<String>? presetReliefMethods,
    int? createdAt,
    int? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      unit: unit ?? this.unit,
      defaultValue: defaultValue ?? this.defaultValue,
      hasSeverity: hasSeverity ?? this.hasSeverity,
      presetTriggers: presetTriggers ?? this.presetTriggers,
      presetReliefMethods: presetReliefMethods ?? this.presetReliefMethods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
