import 'package:flutter_test/flutter_test.dart';
import 'package:homework_buddy/core/constants.dart';
import 'package:homework_buddy/core/due_date_calculator.dart';

void main() {
  const Set<String> noHolidays = {};
  const Set<String> withHoliday = {'2026-11-09'};

  group('DueDateCalculator - school', () {
    test('금 → 다음 월', () {
      expect(
        DueDateCalculator.calculate(Category.school, DateTime(2026, 11, 6), noHolidays),
        '2026-11-09',
      );
    });

    test('평일 → 다음 평일', () {
      expect(
        DueDateCalculator.calculate(Category.school, DateTime(2026, 11, 9), noHolidays),
        '2026-11-10',
      );
    });

    test('공휴일 건너뜀', () {
      expect(
        DueDateCalculator.calculate(Category.school, DateTime(2026, 11, 6), withHoliday),
        '2026-11-10',
      );
    });
  });

  group('DueDateCalculator - english', () {
    test('토 → 다음 주 화', () {
      expect(
        DueDateCalculator.calculate(Category.english, DateTime(2026, 11, 7), noHolidays),
        '2026-11-10',
      );
    });

    test('화 → 7일 뒤 화', () {
      expect(
        DueDateCalculator.calculate(Category.english, DateTime(2026, 11, 10), noHolidays),
        '2026-11-17',
      );
    });

    test('목 → 다음 주 화', () {
      expect(
        DueDateCalculator.calculate(Category.english, DateTime(2026, 11, 12), noHolidays),
        '2026-11-17',
      );
    });

    test('일요일 → 같은 주 화요일(다음 주 화)', () {
      expect(
        DueDateCalculator.calculate(Category.english, DateTime(2026, 11, 8), noHolidays),
        '2026-11-10',
      );
    });
  });

  group('DueDateCalculator - math', () {
    test('금 → 월', () {
      expect(
        DueDateCalculator.calculate(Category.math, DateTime(2026, 11, 6), noHolidays),
        '2026-11-09',
      );
    });

    test('월 → 수', () {
      expect(
        DueDateCalculator.calculate(Category.math, DateTime(2026, 11, 9), noHolidays),
        '2026-11-11',
      );
    });

    test('수 → 금', () {
      expect(
        DueDateCalculator.calculate(Category.math, DateTime(2026, 11, 11), noHolidays),
        '2026-11-13',
      );
    });

    test('화(비수업일) → 가장 가까운 수업일(수)', () {
      expect(
        DueDateCalculator.calculate(Category.math, DateTime(2026, 11, 10), noHolidays),
        '2026-11-11',
      );
    });
  });

  group('DueDateCalculator - essay', () {
    test('논술 → 등록일 + 7일', () {
      expect(
        DueDateCalculator.calculate(Category.essay, DateTime(2026, 11, 6), noHolidays),
        '2026-11-13',
      );
    });
  });

  group('DueDateCalculator - etc', () {
    test('etc → null (사용자 직접 입력)', () {
      expect(
        DueDateCalculator.calculate(Category.etc, DateTime(2026, 11, 6), noHolidays),
        isNull,
      );
    });
  });
}
