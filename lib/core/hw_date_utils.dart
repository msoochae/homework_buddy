class HwDateUtils {
  static String toDateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime fromDateString(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static bool isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  static bool isHoliday(DateTime d, Set<String> holidays) =>
      holidays.contains(toDateString(d));

  static bool isBusinessDay(DateTime d, Set<String> holidays) =>
      !isWeekend(d) && !isHoliday(d, holidays);

  static DateTime nextBusinessDay(DateTime date, Set<String> holidays) {
    var d = date.add(const Duration(days: 1));
    while (!isBusinessDay(d, holidays)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static DateTime nextWeekTuesday(DateTime date) {
    final mondayThisWeek = date.subtract(Duration(days: date.weekday - 1));
    return mondayThisWeek.add(const Duration(days: 8));
  }

  static DateTime nextMathDay(DateTime date) {
    var d = date.add(const Duration(days: 1));
    while (![DateTime.monday, DateTime.wednesday, DateTime.friday].contains(d.weekday)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static int dDay(String dueDateStr) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final due = fromDateString(dueDateStr);
    return due.difference(todayOnly).inDays;
  }

  static String dDayLabel(int d) {
    if (d < 0) return '지연 ${-d}일';
    if (d == 0) return '오늘 마감';
    if (d == 1) return '내일 마감';
    return 'D-$d';
  }

  static String dDayGroupLabel(int d) {
    if (d < 0) return '지연된 숙제 (${-d}일 지남)';
    if (d == 0) return '오늘 마감 숙제';
    if (d == 1) return '내일 마감 숙제';
    return 'D-$d 마감 숙제';
  }

  static bool isUrgent(int dDay) => dDay <= 1;
}
