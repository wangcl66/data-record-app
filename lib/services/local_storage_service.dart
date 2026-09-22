import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 本地 JSON 文件原子存储服务
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();

  LocalStorageService._();

  Directory? _dataDir;
  final Map<String, String> _memoryCache = {}; // 内存缓存

  /// 初始化本地数据存储目录
  Future<Directory> getDataDirectory() async {
    if (_dataDir != null) return _dataDir!;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/data_store');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final recordsDir = Directory('${dir.path}/records');
      if (!await recordsDir.exists()) {
        await recordsDir.create(recursive: true);
      }
      _dataDir = dir;
      return dir;
    } catch (e) {
      debugPrint('获取持久化目录失败，使用临时/备用目录: $e');
      final tempDir = Directory.systemTemp.createTempSync('data_record_app_');
      _dataDir = tempDir;
      return tempDir;
    }
  }

  /// 读取文件内容 (带内存缓存优先及兜底)
  Future<String?> readString(String relativePath) async {
    try {
      final dir = await getDataDirectory();
      final file = File('${dir.path}/$relativePath');
      if (await file.exists()) {
        final content = await file.readAsString();
        _memoryCache[relativePath] = content;
        return content;
      }
      return _memoryCache[relativePath];
    } catch (e) {
      debugPrint('读取文件 [$relativePath] 出错: $e');
      return _memoryCache[relativePath];
    }
  }

  /// 读取 JSON Map
  Future<Map<String, dynamic>?> readJson(String relativePath) async {
    final content = await readString(relativePath);
    if (content == null || content.trim().isEmpty) return null;
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('解析 JSON [$relativePath] 失败: $e');
      return null;
    }
  }

  /// 原子写入文件 (通过 .tmp 文件写入后重命名覆盖，防止断电/崩溃损坏)
  Future<bool> writeString(String relativePath, String content) async {
    _memoryCache[relativePath] = content;
    try {
      final dir = await getDataDirectory();
      final targetFile = File('${dir.path}/$relativePath');
      
      // 确保父目录存在
      final parentDir = targetFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final tmpFile = File('${targetFile.path}.tmp');
      await tmpFile.writeAsString(content, flush: true);

      // 原子重命名覆盖原文件
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(targetFile.path);
      return true;
    } catch (e) {
      debugPrint('原子写入文件 [$relativePath] 出错: $e');
      return false;
    }
  }

  /// 写入 JSON Map
  Future<bool> writeJson(String relativePath, Map<String, dynamic> jsonMap) async {
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(jsonMap);
    return writeString(relativePath, content);
  }

  /// 删除文件
  Future<bool> deleteFile(String relativePath) async {
    _memoryCache.remove(relativePath);
    try {
      final dir = await getDataDirectory();
      final file = File('${dir.path}/$relativePath');
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('删除文件 [$relativePath] 出错: $e');
      return false;
    }
  }
}
