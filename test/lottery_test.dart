import 'package:flutter_test/flutter_test.dart';
import 'package:homework_buddy/data/models/lottery_item.dart';
import 'package:homework_buddy/core/hw_date_utils.dart';
import 'package:homework_buddy/data/models/homework.dart';

void main() {
  group('LotteryPrize Probability Validation', () {
    test('1등부터 7등까지의 확률 합계는 정확히 100.0%여야 한다', () {
      final totalProbability = LotteryPrize.prizes.fold<double>(
        0.0,
        (sum, p) => sum + p.probability,
      );
      expect(totalProbability, closeTo(100.0, 0.0001));
    });

    test('모든 7개 등수의 등수와 보상이 유효해야 한다', () {
      expect(LotteryPrize.prizes.length, 7);
      for (var i = 0; i < 7; i++) {
        expect(LotteryPrize.prizes[i].rank, i + 1);
        expect(LotteryPrize.prizes[i].reward.isNotEmpty, isTrue);
        expect(LotteryPrize.prizes[i].emoji.isNotEmpty, isTrue);
      }
    });
  });

  group('HwDateUtils Group Labels & Formats', () {
    test('dDayGroupLabel - 지연/오늘/내일/미래', () {
      expect(HwDateUtils.dDayGroupLabel(-2), contains('지연된 숙제'));
      expect(HwDateUtils.dDayGroupLabel(0), contains('오늘 마감 숙제'));
      expect(HwDateUtils.dDayGroupLabel(1), contains('내일 마감 숙제'));
      expect(HwDateUtils.dDayGroupLabel(3), contains('D-3 마감 숙제'));
    });
  });

  group('Homework timeRangeText', () {
    test('시작 시간과 종료 시간 모두 있는 경우', () {
      final hw = Homework(
        id: '1',
        date: '2026-11-22',
        category: 'math',
        title: '연산',
        status: 'registered',
        progress: 0,
        createdBy: 'child',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        startTime: '14:00',
        endTime: '15:30',
      );
      expect(hw.timeRangeText, '14:00 ~ 15:30');
    });

    test('시간이 없는 경우 null', () {
      final hw = Homework(
        id: '2',
        date: '2026-11-22',
        category: 'school',
        title: '일기',
        status: 'registered',
        progress: 0,
        createdBy: 'child',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(hw.timeRangeText, isNull);
    });
  });
}
