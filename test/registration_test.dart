import 'package:flutter_test/flutter_test.dart';
import 'package:homework_buddy/core/constants.dart';
import 'package:homework_buddy/core/registration_checker.dart';

void main() {
  const noHolidays = <String>{};
  const withHoliday = <String>{'2026-11-09'};

  group('RegistrationChecker.isRequiredDay', () {
    test('school - 평일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.school, DateTime(2026, 11, 9), noHolidays), isTrue);
    });

    test('school - 주말은 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.school, DateTime(2026, 11, 7), noHolidays), isFalse);
    });

    test('school - 공휴일은 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.school, DateTime(2026, 11, 9), withHoliday), isFalse);
    });

    test('english - 화요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.english, DateTime(2026, 11, 10), noHolidays), isTrue);
    });

    test('english - 목요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.english, DateTime(2026, 11, 12), noHolidays), isTrue);
    });

    test('english - 토요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.english, DateTime(2026, 11, 7), noHolidays), isTrue);
    });

    test('english - 월요일은 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.english, DateTime(2026, 11, 9), noHolidays), isFalse);
    });

    test('math - 월요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.math, DateTime(2026, 11, 9), noHolidays), isTrue);
    });

    test('math - 수요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.math, DateTime(2026, 11, 11), noHolidays), isTrue);
    });

    test('math - 금요일은 필수', () {
      expect(RegistrationChecker.isRequiredDay(Category.math, DateTime(2026, 11, 13), noHolidays), isTrue);
    });

    test('math - 화요일은 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.math, DateTime(2026, 11, 10), noHolidays), isFalse);
    });

    test('essay - 항상 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.essay, DateTime(2026, 11, 10), noHolidays), isFalse);
    });

    test('etc - 항상 필수 아님', () {
      expect(RegistrationChecker.isRequiredDay(Category.etc, DateTime(2026, 11, 10), noHolidays), isFalse);
    });
  });

  group('RegistrationChecker.isFutureDate', () {
    test('미래 날짜는 true', () {
      expect(RegistrationChecker.isFutureDate(DateTime.now().add(const Duration(days: 1))), isTrue);
    });

    test('오늘은 false', () {
      final t = DateTime.now();
      expect(RegistrationChecker.isFutureDate(DateTime(t.year, t.month, t.day)), isFalse);
    });
  });
}
