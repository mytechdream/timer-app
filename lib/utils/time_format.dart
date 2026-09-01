String formatDigitalTime(int totalSeconds) {
  final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final int hours = safeSeconds ~/ 3600;
  final int minutes = (safeSeconds % 3600) ~/ 60;
  final int seconds = safeSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatChineseDuration(int totalSeconds) {
  final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final int hours = safeSeconds ~/ 3600;
  final int minutes = (safeSeconds % 3600) ~/ 60;
  final int seconds = safeSeconds % 60;
  return '$hours 小时   $minutes 分钟   $seconds 秒';
}

String formatMinuteLabel(int totalSeconds) {
  final int minutes = (totalSeconds / 60).round();
  return '$minutes分钟';
}

String formatBubbleTime(int totalSeconds) {
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
