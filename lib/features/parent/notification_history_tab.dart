import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/hw_date_utils.dart';
import '../../data/models/homework.dart';

class NotificationHistoryTab extends ConsumerWidget {
  const NotificationHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final from = HwDateUtils.toDateString(now.subtract(const Duration(days: 14)));
    final to = HwDateUtils.toDateString(now);
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 내역 🔔'),
      ),
      body: ref.watch(homeworksRangeProvider((from, to))).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (homeworks) {
          final sorted = ([...homeworks]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
          if (sorted.isEmpty) return const Center(child: Text('알림 내역이 없어요'));
          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (ctx, i) {
              final hw = sorted[i];
              final cat = Category.values.firstWhere((c) => c.name == hw.category, orElse: () => Category.etc);
              return ListTile(
                leading: CircleAvatar(child: Text(cat.emoji)),
                title: Text(_buildMsg(hw, cat)),
                subtitle: Text(
                  '${hw.updatedAt.month}/${hw.updatedAt.day} '
                  '${hw.updatedAt.hour.toString().padLeft(2, '0')}:${hw.updatedAt.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _buildMsg(Homework hw, Category cat) {
    switch (hw.status) {
      case 'none':
        return '채이현이 [${cat.displayName}] 숙제 없음으로 등록했어요';
      case 'done':
        return '채이현이 [${cat.displayName}] ${hw.title}을(를) 완료했어요 🎉';
      case 'in_progress':
        return '[${cat.displayName}] ${hw.title} 진행률 ${hw.progress}%';
      default:
        final d = hw.dueDate != null ? ' (기한 ${hw.dueDate!.substring(5).replaceAll('-', '/')})' : '';
        return '채이현이 [${cat.displayName}] 숙제를 등록했어요: ${hw.title}$d';
    }
  }
}
