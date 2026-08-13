/// Formats [ms] milliseconds as "m:ss" or "h:mm:ss".
String formatDuration(int ms) {
  if (ms <= 0) return '0:00';
  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final secondsStr = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final minutesStr = minutes.toString().padLeft(2, '0');
    return '$hours:$minutesStr:$secondsStr';
  }
  return '$minutes:$secondsStr';
}

String formatDurationFromDuration(Duration d) => formatDuration(d.inMilliseconds);

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}

String formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  if (diff.inDays < 14) return weekdays[time.weekday - 1];
  return '${time.day} ${months[time.month - 1]}';
}

String pluralize(int count, String singular, [String? plural]) {
  if (count == 1) return '1 $singular';
  return '$count ${plural ?? '${singular}s'}';
}
