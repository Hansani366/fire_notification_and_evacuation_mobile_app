// Small formatting helpers shared across screens.

/// "Scanned 4s ago" / "Scanned 2m ago" from a last-scan timestamp.
String scannedAgo(DateTime when, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(when);
  final secs = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (secs < 60) return 'Scanned ${secs}s ago';
  final mins = d.inMinutes;
  if (mins < 60) return 'Scanned ${mins}m ago';
  return 'Scanned ${d.inHours}h ago';
}

/// "0:32 ago" style m:ss elapsed label for the live incident timer.
String elapsedAgo(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')} ago';
}

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "Thursday, 2 July" — lock-screen date line.
String lockDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// 12-hour clock "2:14" (no am/pm), matching the lock screen.
String clockTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')}';
}
