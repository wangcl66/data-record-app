import 'package:intl/intl.dart';

/// 日期与时间格式化工具类
class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthDayFormat = DateFormat('MM-dd');

  /// 格式化为 yyyy-MM-dd
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  /// 格式化为 yyyy-MM-dd HH:mm
  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// 格式化时间戳为 yyyy-MM-dd HH:mm
  static String formatTimestamp(int timestamp) =>
      _dateTimeFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  /// 格式化为 HH:mm
  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  /// 格式化时间戳为 HH:mm
  static String formatTimestampTime(int timestamp) =>
      _timeFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  /// 格式化为 MM-dd (图表坐标轴常用)
  static String formatMonthDay(DateTime dateTime) => _monthDayFormat.format(dateTime);

  /// 将分钟数转换为可读字符串 (如 195 分钟 -> "3小时15分", 45 分钟 -> "45分钟")
  static String formatDurationMinutes(int minutes) {
    if (minutes <= 0) return '0分钟';
    final hours = minutes ~/ 60;
    final remainMins = minutes % 60;
    if (hours > 0 && remainMins > 0) {
      return '$hours小时$remainMins分';
    } else if (hours > 0) {
      return '$hours小时';
    } else {
      return '$remainMins分钟';
    }
  }

  /// 毫秒时长格式化为计时器字符串 "HH:mm:ss"
  static String formatTimerDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  /// 获取相对时间描述 (如 "刚刚", "10分钟前", "昨天", "3天前")
  static String getRelativeTime(int timestamp) {
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(target);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天 ${formatTime(target)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return formatDate(target);
    }
  }

  /// 获取友好的日期分组标题 (如 "今天", "昨天", "2026年9月20日 星期日")
  static String getGroupHeaderTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '今天 (${formatDate(date)})';
    } else if (targetDate == yesterday) {
      return '昨天 (${formatDate(date)})';
    } else {
      return formatDate(date);
    }
  }
}
