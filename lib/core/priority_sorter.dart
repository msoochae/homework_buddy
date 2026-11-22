import '../data/models/homework.dart';
import 'hw_date_utils.dart';

class PrioritySorter {
  static const _categoryOrder = ['school', 'math', 'english', 'essay', 'etc'];

  static List<Homework> sort(List<Homework> homeworks) {
    final active = homeworks.where((h) =>
        h.status == 'registered' || h.status == 'in_progress').toList();

    active.sort((a, b) {
      final dA = a.dueDate != null ? HwDateUtils.dDay(a.dueDate!) : 999;
      final dB = b.dueDate != null ? HwDateUtils.dDay(b.dueDate!) : 999;

      if (dA != dB) return dA.compareTo(dB);
      if (a.progress != b.progress) return a.progress.compareTo(b.progress);

      final cA = _categoryOrder.indexOf(a.category);
      final cB = _categoryOrder.indexOf(b.category);
      if (cA != cB) return cA.compareTo(cB);

      return a.createdAt.compareTo(b.createdAt);
    });

    return active;
  }
}
