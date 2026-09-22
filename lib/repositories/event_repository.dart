import '../models/event_model.dart';
import '../services/local_storage_service.dart';

/// 事件仓储接口与实现
class EventRepository {
  final LocalStorageService _storage = LocalStorageService.instance;
  static const String _eventsFile = 'events.json';

  /// 获取所有事件列表
  Future<List<EventModel>> getAllEvents() async {
    final json = await _storage.readJson(_eventsFile);
    if (json == null || json['events'] == null) {
      // 若首次打开无数据，生成默认示例事件（包含偏头痛、喝水等）
      final defaultEvents = _createDefaultEvents();
      await saveEvents(defaultEvents);
      return defaultEvents;
    }

    final list = json['events'] as List<dynamic>;
    return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 保存完整事件列表
  Future<bool> saveEvents(List<EventModel> events) async {
    final map = {
      'version': 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'events': events.map((e) => e.toJson()).toList(),
    };
    return _storage.writeJson(_eventsFile, map);
  }

  /// 新增单个事件
  Future<bool> addEvent(EventModel event) async {
    final events = await getAllEvents();
    events.insert(0, event);
    return saveEvents(events);
  }

  /// 更新单个事件
  Future<bool> updateEvent(EventModel event) async {
    final events = await getAllEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      return saveEvents(events);
    }
    return false;
  }

  /// 删除单个事件
  Future<bool> deleteEvent(String eventId) async {
    final events = await getAllEvents();
    events.removeWhere((e) => e.id == eventId);
    final success = await saveEvents(events);
    // 同时清理该事件的记录文件
    await _storage.deleteFile('records/$eventId.json');
    return success;
  }

  /// 预置的默认事件数据
  List<EventModel> _createDefaultEvents() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      EventModel(
        id: 'evt_migraine_default',
        name: '偏头痛发作记录',
        description: '记录每次偏头痛发作起止时间、诱因、严重程度及缓解药物',
        type: EventType.duration,
        iconCodePoint: 0xf58a, // Icons.healing_rounded 或 brain
        colorValue: 0xFFE91E63, // 玫红/警示色
        unit: '小时',
        hasSeverity: true,
        presetTriggers: [
          '昨晚熬夜',
          '工作压力大',
          '咖啡因/饮浓茶',
          '天气剧变/受凉',
          '强光刺激/长时间盯屏',
          '跳餐/低血糖',
        ],
        presetReliefMethods: [
          '口服布洛芬 400mg',
          '对乙酰氨基酚',
          '暗室平躺冷敷',
          '闭目静养',
          '补充电解质温水',
          '深度睡眠',
        ],
        createdAt: now - 86400000 * 30,
        updatedAt: now,
      ),
      EventModel(
        id: 'evt_water_default',
        name: '每日喝水打卡',
        description: '保持规律饮水，每次喝水 250ml~300ml',
        type: EventType.instant,
        iconCodePoint: 0xe6e8, // Icons.water_drop_rounded
        colorValue: 0xFF2196F3, // 蓝色
        unit: 'ml',
        defaultValue: 300,
        hasSeverity: false,
        createdAt: now - 86400000 * 15,
        updatedAt: now,
      ),
      EventModel(
        id: 'evt_idea_default',
        name: '灵感与闪念记录',
        description: '记录工作生活中的灵光一闪',
        type: EventType.instant,
        iconCodePoint: 0xe3a8, // Icons.lightbulb_rounded
        colorValue: 0xFFFF9800, // 琥珀橙
        unit: '条',
        hasSeverity: false,
        createdAt: now - 86400000 * 10,
        updatedAt: now,
      ),
    ];
  }
}
