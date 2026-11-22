import 'constants.dart';
import 'hw_date_utils.dart';

class DueDateCalculator {
  static String? calculate(Category category, DateTime registerDate, Set<String> holidays) {
    switch (category) {
      case Category.school:
        return HwDateUtils.toDateString(
          HwDateUtils.nextBusinessDay(registerDate, holidays),
        );
      case Category.english:
        return HwDateUtils.toDateString(
          HwDateUtils.nextWeekTuesday(registerDate),
        );
      case Category.math:
        return HwDateUtils.toDateString(
          HwDateUtils.nextMathDay(registerDate),
        );
      case Category.essay:
        return HwDateUtils.toDateString(
          registerDate.add(const Duration(days: 7)),
        );
      case Category.etc:
        return null;
    }
  }
}
