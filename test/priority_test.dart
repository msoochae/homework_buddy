import 'package:flutter_test/flutter_test.dart';
import 'package:homework_buddy/core/priority_sorter.dart';
import 'package:homework_buddy/data/models/homework.dart';

Homework _hw({
  required String id,
  required String dueDate,
  required String category,
  String status = 'registered',
  int progress = 0,
  DateTime? createdAt,
}) =>
    Homework(
      id: id,
      date: '2026-11-19',
      category: category,
      title: 'test',
      dueDate: dueDate,
      status: status,
      progress: progress,
      createdBy: 'child',
      createdAt: createdAt ?? DateTime(2026, 11, 19, 10, 0),
      updatedAt: DateTime(2026, 11, 19, 10, 0),
    );

void main() {
  group('PrioritySorter', () {
    test('지연 항목이 먼저', () {
      final sorted = PrioritySorter.sort([
        _hw(id: 'a', dueDate: '2026-11-25', category: 'school'),
        _hw(id: 'b', dueDate: '2026-11-18', category: 'math'),
        _hw(id: 'c', dueDate: '2026-11-19', category: 'english'),
      ]);
      expect(sorted.first.id, 'b');
    });

    test('같은 D-DAY → 진행률 낮은 순', () {
      final sorted = PrioritySorter.sort([
        _hw(id: 'a', dueDate: '2026-11-21', category: 'school', status: 'in_progress', progress: 50),
        _hw(id: 'b', dueDate: '2026-11-21', category: 'math', status: 'registered', progress: 0),
      ]);
      expect(sorted.first.id, 'b');
    });

    test('같은 D-DAY·진행률 → 과목 순서(school > math > english > essay > etc)', () {
      final sorted = PrioritySorter.sort([
        _hw(id: 'e', dueDate: '2026-11-21', category: 'etc'),
        _hw(id: 'essay', dueDate: '2026-11-21', category: 'essay'),
        _hw(id: 'm', dueDate: '2026-11-21', category: 'math'),
        _hw(id: 's', dueDate: '2026-11-21', category: 'school'),
        _hw(id: 'en', dueDate: '2026-11-21', category: 'english'),
      ]);
      expect(sorted.map((h) => h.id).toList(), ['s', 'm', 'en', 'essay', 'e']);
    });

    test('done·none 제외', () {
      final sorted = PrioritySorter.sort([
        _hw(id: 'done', dueDate: '2026-11-20', category: 'school', status: 'done'),
        _hw(id: 'none', dueDate: '2026-11-20', category: 'math', status: 'none'),
        _hw(id: 'active', dueDate: '2026-11-20', category: 'english'),
      ]);
      expect(sorted.length, 1);
      expect(sorted.first.id, 'active');
    });
  });
}
