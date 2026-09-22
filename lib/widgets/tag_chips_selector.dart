import 'package:flutter/material.dart';

/// 标签多选与动态添加组件 (用于发作诱因、缓解手段选择)
class TagChipsSelector extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> presetTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final String addHintText;
  final Color activeColor;

  const TagChipsSelector({
    super.key,
    required this.title,
    required this.icon,
    required this.presetTags,
    required this.selectedTags,
    required this.onChanged,
    this.addHintText = '添加新标签...',
    this.activeColor = const Color(0xFF3F51B5),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAvailableTags = <String>{...presetTags, ...selectedTags}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: activeColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddTagDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('自定义'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (allAvailableTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '暂无预设标签，点击右上角「自定义」添加',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allAvailableTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                selectedColor: activeColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? activeColor
                        : theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                onSelected: (bool selected) {
                  final newSelected = List<String>.from(selectedTags);
                  if (selected) {
                    newSelected.add(tag);
                  } else {
                    newSelected.remove(tag);
                  }
                  onChanged(newSelected);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('新增 $title'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: addHintText,
              prefixIcon: Icon(icon, size: 20),
            ),
            onSubmitted: (value) {
              _handleAddTag(context, textController.text.trim());
              Navigator.pop(dialogCtx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                _handleAddTag(context, textController.text.trim());
                Navigator.pop(dialogCtx);
              },
              child: const Text('添加并选中'),
            ),
          ],
        );
      },
    );
  }

  void _handleAddTag(BuildContext context, String tag) {
    if (tag.isNotEmpty && !selectedTags.contains(tag)) {
      final updated = List<String>.from(selectedTags)..add(tag);
      onChanged(updated);
    }
  }
}
