import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../../widgets/tag_chips_selector.dart';

/// 新建与编辑事件对话框
class EventFormDialog extends StatefulWidget {
  final EventModel? initialEvent;
  final ValueChanged<EventModel> onSave;

  const EventFormDialog({
    super.key,
    this.initialEvent,
    required this.onSave,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _unitController;
  late TextEditingController _defaultValController;

  late EventType _type;
  late int _iconCodePoint;
  late int _colorValue;
  late bool _hasSeverity;
  late List<String> _presetTriggers;
  late List<String> _presetReliefMethods;

  // 预设图标候选
  final List<IconData> _curatedIcons = [
    Icons.healing_rounded,
    Icons.water_drop_rounded,
    Icons.lightbulb_rounded,
    Icons.fitness_center_rounded,
    Icons.bedtime_rounded,
    Icons.restaurant_rounded,
    Icons.medication_rounded,
    Icons.directions_run_rounded,
    Icons.smoke_free_rounded,
    Icons.mood_bad_rounded,
    Icons.star_rounded,
    Icons.schedule_rounded,
  ];

  // 预设颜色候选 (UI/UX Pro Max 调色板)
  final List<int> _curatedColors = [
    0xFFE91E63, // 玫红
    0xFF3F51B5, // 靛蓝
    0xFF2196F3, // 经典蓝
    0xFF009688, // 蓝绿
    0xFF4CAF50, // 活力绿
    0xFFFF9800, // 琥珀橙
    0xFF9C27B0, // 紫罗兰
    0xFF795548, // 咖啡棕
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _nameController = TextEditingController(text: event?.name ?? '');
    _descController = TextEditingController(text: event?.description ?? '');
    _unitController = TextEditingController(text: event?.unit ?? '');
    _defaultValController = TextEditingController(
      text: event?.defaultValue != null ? event!.defaultValue.toString() : '',
    );

    _type = event?.type ?? EventType.duration;
    _iconCodePoint = event?.iconCodePoint ?? _curatedIcons.first.codePoint;
    _colorValue = event?.colorValue ?? _curatedColors.first;
    _hasSeverity = event?.hasSeverity ?? true;
    _presetTriggers = List<String>.from(event?.presetTriggers ?? [
      '昨晚熬夜',
      '工作压力大',
      '咖啡因/饮浓茶',
      '天气剧变/受凉',
      '强光刺激',
    ]);
    _presetReliefMethods = List<String>.from(event?.presetReliefMethods ?? [
      '口服布洛芬 400mg',
      '对乙酰氨基酚',
      '暗室平躺冷敷',
      '闭目静养',
      '深度睡眠',
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _unitController.dispose();
    _defaultValController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialEvent != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 标题栏
              Row(
                children: [
                  Text(
                    isEditing ? '编辑事件' : '新建事件任务',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 可滚动表单内容
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 事件名称
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '事件名称 *',
                          hintText: '例如: 偏头痛发作、每日喝水、灵感记录',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入事件名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 事件描述
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '事件描述 / 备注指引',
                          hintText: '简要描述该事件记录的目的或提示',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 事件类型选择 (瞬时打卡 vs 持续时段)
                      Text(
                        '事件记录模式',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<EventType>(
                        segments: const [
                          ButtonSegment<EventType>(
                            value: EventType.duration,
                            label: Text('持续时段/症状型'),
                            icon: Icon(Icons.timer_outlined),
                          ),
                          ButtonSegment<EventType>(
                            value: EventType.instant,
                            label: Text('单点打卡型'),
                            icon: Icon(Icons.touch_app_outlined),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (Set<EventType> newSelection) {
                          setState(() {
                            _type = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 图标选择
                      Text(
                        '图标',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _curatedIcons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final icon = _curatedIcons[index];
                            final isSelected = icon.codePoint == _iconCodePoint;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _iconCodePoint = icon.codePoint;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(_colorValue).withOpacity(0.2)
                                      : theme.colorScheme.surfaceVariant
                                          .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(_colorValue)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? Color(_colorValue)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 主题颜色选择
                      Text(
                        '主题色',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _curatedColors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final colorVal = _curatedColors[index];
                            final isSelected = colorVal == _colorValue;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _colorValue = colorVal;
                                });
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Color(colorVal).withOpacity(0.5),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 时段/偏头痛模式专属配置
                      if (_type == EventType.duration) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('启用 1-10 级疼痛/严重程度评分'),
                          subtitle: const Text('记录每次发作时的身体感受严重等级'),
                          value: _hasSeverity,
                          onChanged: (val) => setState(() => _hasSeverity = val),
                        ),
                        const SizedBox(height: 12),
                        TagChipsSelector(
                          title: '预设诱因标签库',
                          icon: Icons.psychology_alt_rounded,
                          presetTags: _presetTriggers,
                          selectedTags: _presetTriggers,
                          activeColor: Color(_colorValue),
                          onChanged: (tags) {
                            setState(() => _presetTriggers = tags);
                          },
                        ),
                        const SizedBox(height: 16),
                        TagChipsSelector(
                          title: '预设缓解方式词库',
                          icon: Icons.healing_rounded,
                          presetTags: _presetReliefMethods,
                          selectedTags: _presetReliefMethods,
                          activeColor: Color(_colorValue),
                          onChanged: (tags) {
                            setState(() => _presetReliefMethods = tags);
                          },
                        ),
                      ] else ...[
                        // 瞬时打卡型配置
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _unitController,
                                decoration: const InputDecoration(
                                  labelText: '度量单位',
                                  hintText: '例如: ml, 次, km',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _defaultValController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '默认数值',
                                  hintText: '例如: 250',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 底部提交按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(_colorValue),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? '保存修改' : '立即创建'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final initial = widget.initialEvent;

    final event = EventModel(
      id: initial?.id ?? 'evt_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      type: _type,
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null,
      defaultValue: double.tryParse(_defaultValController.text.trim()),
      hasSeverity: _hasSeverity,
      presetTriggers: _presetTriggers,
      presetReliefMethods: _presetReliefMethods,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(event);
    Navigator.pop(context);
  }
}
