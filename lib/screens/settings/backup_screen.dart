import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/event_provider.dart';
import '../../services/backup_service.dart';
import '../../services/local_storage_service.dart';

/// 本地数据备份与恢复管理页面
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;
  String _previewJson = '';
  String _storageDirPath = '';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final json = await _backupService.exportBackupJson();
    final dir = await LocalStorageService.instance.getDataDirectory();
    if (mounted) {
      setState(() {
        _previewJson = json;
        _storageDirPath = dir.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份与导出'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明卡片
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.security_rounded,
                              color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '纯本地离线隐私保护',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '您的所有偏头痛规律、生活打卡数据均存储于本机，未上传任何外部云端。建议定期导出备份。',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 导出操作
                  Text(
                    '数据导出',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleShareBackup,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('分享 / 导出备份文件'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCopyJson,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('复制 JSON 内容'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 恢复操作
                  Text(
                    '数据恢复',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _handlePasteRestore,
                    icon: const Icon(Icons.restore_page_rounded),
                    label: const Text('从剪贴板 JSON 恢复数据'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 备份数据预览
                  Text(
                    '备份数据实时预览 (JSON)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 240,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _previewJson,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 本地存储文件目录展示卡片
                  Text(
                    '本地存储文件目录',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.folder_open_rounded,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '本机物理存储绝对路径：',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: '复制目录路径',
                              onPressed: () async {
                                if (_storageDirPath.isNotEmpty) {
                                  await Clipboard.setData(
                                      ClipboardData(text: _storageDirPath));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('已复制存储目录路径到剪贴板')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _storageDirPath.isNotEmpty
                              ? _storageDirPath
                              : '正在获取存储路径...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '存放 events.json 及 records/*.json 分层文件，应用离线直接读写本目录。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _handleShareBackup() async {
    setState(() => _isProcessing = true);
    try {
      final filePath = await _backupService.exportBackupToFile();
      if (filePath != null && mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: '我的时间与数据记录应用备份',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCopyJson() async {
    final json = await _backupService.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已成功复制完整备份 JSON 到剪贴板')),
      );
    }
  }

  Future<void> _handlePasteRestore() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('剪贴板中未检测到有效文本')),
        );
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确认从剪贴板恢复?'),
        content: const Text('恢复操作将用剪贴板中的数据覆盖当前所有记录，请谨慎操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isProcessing = true);
              final success =
                  await _backupService.restoreFromBackupJson(text);
              if (!mounted) return;
              setState(() => _isProcessing = false);
              if (success) {
                await context.read<EventProvider>().loadEvents();
                await _loadPreview();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已成功恢复！')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据格式有误，恢复失败')),
                );
              }
            },
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }
}
