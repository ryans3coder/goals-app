String formatDurationMinutesSeconds(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatDurationSecondsLabel(
  int durationSeconds, {
  required String zeroLabel,
}) {
  if (durationSeconds <= 0) {
    return zeroLabel;
  }
  return formatDurationMinutesSeconds(
    Duration(seconds: durationSeconds),
  );
}
