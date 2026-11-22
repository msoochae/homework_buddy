import 'constants.dart';
import 'hw_date_utils.dart';

class RegistrationChecker {
  static bool isRequiredDay(Category category, DateTime date, Set<String> holidays) {
    switch (category) {
      case Category.school:
        return HwDateUtils.isBusinessDay(date, holidays);
      case Category.english:
        return [DateTime.tuesday, DateTime.thursday, DateTime.saturday]
            .contains(date.weekday);
      case Category.math:
        return [DateTime.monday, DateTime.wednesday, DateTime.friday]
            .contains(date.weekday);
      case Category.essay:
      case Category.etc:
        return false;
    }
  }

  static bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return date.isAfter(todayOnly);
  }
}
