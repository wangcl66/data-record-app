import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/event_model.dart';
import '../../../models/record_model.dart';
import '../../../widgets/severity_slider.dart';
import '../../../widgets/tag_chips_selector.dart';

/// 新增 / 编辑单次记录 BottomSheet 抽屉表单
class RecordFormSheet extends StatefulWidget {
  final EventModel event;
  final RecordModel? initialRecord;
  final ValueChanged<RecordModel> onSave;

  const RecordFormSheet({
    super.key,
    required this.event,
    this.initialRecord,
    required this.onSave,
  });

  @override
  State<RecordFormSheet> createState() => _RecordFormSheetState();
}

class _RecordFormSheetState extends State<RecordFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDateTime;
  DateTime? _endDateTime;
  late bool _isOngoing;
  late int _severity;
  late List<String> _triggers;
  late List<String> _reliefMethods;
  late TextEditingController _valController;
  late TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    final now = DateTime.now();

    _startDateTime = rec != null
        ? DateTime.fromMillisecondsSinceEpoch(rec.startTime)
        : now;
    _endDateTime = rec?.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(rec!.endTime!)
        : (widget.event.type == EventType.duration && rec == null
            ? now.add(const Duration(hours: 2))
            : (widget.event.type == EventType.instant ? now : null));

    _isOngoing = rec?.isOngoing ?? false;
    _severity = rec?.severity ?? (widget.event.hasSeverity ? 7 : 0);
    _triggers = List<String>.from(rec?.triggers ?? []);
    _reliefMethods = List<String>.from(rec?.reliefMethods ?? []);
    _valController = TextEditingController(
      text: rec?.value != null
          ? rec!.value.toString()
          : (widget.event.defaultValue?.toString() ?? ''),
    );
    _remarkController = TextEditingController(text: rec?.remark ?? '');
  }

  @override
  void dispose() {
    _valController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  int get _calculatedDurationMinutes {
    if (_endDateTime != null && _endDateTime!.isAfter(_startDateTime)) {
      return _endDateTime!.difference(_startDateTime).inMinutes;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDurationType = widget.event.type == EventType.duration;
    final isEditing = widget.initialRecord != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部标题
                Row(
                  children: [
                    Icon(widget.event.iconData,
                        color: widget.event.color, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? '编辑记录' : '新增 ${widget.event.name}',
                      style: theme.textTheme.titleMedium?.copyWith(
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
                const Divider(height: 16),

                // 表单主要内容
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 起止时间选择
                        if (isDurationType) ...[
                          _buildDateTimePickerTile(
                            context,
                            label: '开始时间',
                            dateTime: _startDateTime,
                            onChanged: (newDt) {
                              setState(() {
                                _startDateTime = newDt;
                                if (_endDateTime != null &&
                                    _endDateTime!.isBefore(_startDateTime)) {
                                  _endDateTime =
                                      _startDateTime.add(const Duration(hours: 1));
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!_isOngoing) ...[
                            _buildDateTimePickerTile(
                              context,
                              label: '结束时间',
                              dateTime: _endDateTime ??
                                  _startDateTime.add(const Duration(hours: 1)),
                              onChanged: (newDt) {
                                setState(() {
                                  _endDateTime = newDt;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            // 持续时长提示条
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.event.color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 18, color: widget.event.color),
                                  const SizedBox(width: 8),
                                  Text(
                                    '持续时长: ${DateFormatter.formatDurationMinutes(_calculatedDurationMinutes)}',
                                    style: TextStyle(
                                      color: widget.event.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('仍在发作/进行中'),
                            subtitle: const Text('开启后暂不设结束时间，继续计时'),
                            value: _isOngoing,
                            onChanged: (val) {
                              setState(() {
                                _isOngoing = val;
                                if (val) _endDateTime = null;
                              });
                            },
                          ),
                        ] else ...[
                          _buildDateTimePickerTile(
                            context,
                            label: '发生时间',
                            dateTime: _startDateTime,
                            onChanged: (newDt) =>
                                setState(() => _startDateTime = newDt),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 严重程度评分 (VAS 1-10)
                        if (widget.event.hasSeverity) ...[
                          SeveritySlider(
                            value: _severity,
                            onChanged: (val) => setState(() => _severity = val),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 发病诱因多选
                        if (isDurationType) ...[
                          TagChipsSelector(
                            title: '发病诱因 (Triggers)',
                            icon: Icons.psychology_alt_rounded,
                            presetTags: widget.event.presetTriggers,
                            selectedTags: _triggers,
                            activeColor: Colors.red,
                            addHintText: '如: 熬夜、咖啡、暴晒...',
                            onChanged: (tags) =>
                                setState(() => _triggers = tags),
                          ),
                          const SizedBox(height: 16),

                          // 缓解应对手段
                          TagChipsSelector(
                            title: '缓解方式 (Relief Methods)',
                            icon: Icons.healing_rounded,
                            presetTags: widget.event.presetReliefMethods,
                            selectedTags: _reliefMethods,
                            activeColor: const Color(0xFF2E7D32),
                            addHintText: '如: 布洛芬400mg、暗室冷敷...',
                            onChanged: (tags) =>
                                setState(() => _reliefMethods = tags),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 瞬时型数值输入
                        if (!isDurationType && widget.event.unit != null) ...[
                          TextFormField(
                            controller: _valController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '记录数值 (${widget.event.unit})',
                              hintText: '请输入本次数值',
                              prefixIcon: const Icon(Icons.numbers_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 详细描述/伴随症状
                        TextFormField(
                          controller: _remarkController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: isDurationType
                                ? '伴随症状与详细描述'
                                : '备注描述',
                            hintText: isDurationType
                                ? '例如: 右侧太阳穴搏动性跳痛，畏光畏声，伴随恶心...'
                                : '输入本次打卡补充信息...',
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 底部操作栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.event.color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isEditing ? '保存修改' : '确认记录'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePickerTile(
    BuildContext context, {
    required String label,
    required DateTime dateTime,
    required ValueChanged<DateTime> onChanged,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dateTime),
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              DateFormatter.formatDateTime(dateTime),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final initial = widget.initialRecord;
    final isDuration = widget.event.type == EventType.duration;

    final durationMins = isDuration && !_isOngoing && _endDateTime != null
        ? _calculatedDurationMinutes
        : null;

    final record = RecordModel(
      id: initial?.id ?? 'rec_${DateTime.now().microsecondsSinceEpoch}',
      eventId: widget.event.id,
      startTime: _startDateTime.millisecondsSinceEpoch,
      endTime: !_isOngoing && _endDateTime != null
          ? _endDateTime!.millisecondsSinceEpoch
          : null,
      durationMinutes: durationMins,
      isOngoing: _isOngoing,
      severity: widget.event.hasSeverity ? _severity : null,
      triggers: _triggers,
      reliefMethods: _reliefMethods,
      value: double.tryParse(_valController.text.trim()) ??
          (isDuration && durationMins != null ? durationMins / 60.0 : null),
      remark: _remarkController.text.trim(),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(record);
    Navigator.pop(context);
  }
}
