String formatCompact(int seconds) {
  final normalized = seconds < 0 ? 0 : seconds;
  final minutes = normalized ~/ 60;
  final remainingSeconds = normalized % 60;
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}
