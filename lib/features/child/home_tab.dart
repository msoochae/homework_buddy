import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/hw_date_utils.dart';
import '../../core/priority_sorter.dart';
import '../../data/models/homework.dart';
import '../../data/repositories/streak_repository.dart';
import '../shared/unregistered_banner.dart';
import '../shared/homework_card.dart';
import 'detail_sheet.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final Set<String> _shownPraiseIds = {};

  void _checkPraises(List<PraiseItem> praises, String familyCode) {
    for (final p in praises) {
      if (!_shownPraiseIds.contains(p.id)) {
        _shownPraiseIds.add(p.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                '${p.emoji} ${p.senderName}의 칭찬 하이파이브!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    '\"${p.praiseText}\"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '부모님이 이현이의 멋진 노력을 응원해요! 💖',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(streakRepositoryProvider).markPraiseAsRead(familyCode, p.id);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: const Text('하이파이브! ✋', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  Future<void> _handleQuickComplete(Homework hw, String familyCode, String today) async {
    final now = DateTime.now();
    final updated = hw.copyWith(
      status: 'done',
      progress: 100,
      updatedAt: now,
      completedAt: now,
    );
    await ref.read(homeworkRepositoryProvider).update(updated);

    // Check streak
    final bonus = await ref
        .read(streakRepositoryProvider)
        .checkAndIncrementStreak(familyCode, today);
    if (bonus > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 7일 연속 달성 축하! 보너스 뽑기권 1장이 지급되었습니다! 🎟️'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = HwDateUtils.toDateString(DateTime.now());
    final familyCode = ref.watch(familyCodeProvider);
    final streakAsync = ref.watch(streakStatsProvider);
    final praisesAsync = ref.watch(unreadPraisesProvider);

    praisesAsync.whenData((praises) => _checkPraises(praises, familyCode));

    final streak = streakAsync.value ?? const StreakStats();

    return ref.watch(activeAndTodayHomeworksProvider(today)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (homeworks) {
        // Today-specific homeworks for the unregistered banner
        final todayHw = homeworks.where((h) => h.date == today).toList();
        // Priority sorted list of active (uncompleted) homeworks
        final sorted = PrioritySorter.sort(homeworks);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('오늘의 숙제 📚'),
              floating: true,
              automaticallyImplyLeading: false,
            ),

            // Streak Flame Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            streak.streakCount > 0
                                ? '${streak.streakCount}일 연속 완주 중!'
                                : '오늘 숙제를 완료하고 연속 기록을 시작해보세요!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            streak.streakCount > 0
                                ? '7일 달성 시마다 보너스 뽑기권 증정 (현재 ${streak.streakCount % 7}/7일)'
                                : '매일 매일 불꽃을 키워보세요 ✨',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: UnregisteredBanner(homeworks: todayHw, date: DateTime.now()),
            ),

            if (sorted.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        '남은 숙제가 없어요!\n오늘도 정말 수고 많았어요 😊',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final hw = sorted[i];
                    final prevDDay = i > 0 ? sorted[i - 1].dDay : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (prevDDay == null || prevDDay != hw.dDay)
                          _DayHeader(dDay: hw.dDay),
                        HomeworkCard(
                          hw: hw,
                          onTap: () => showModalBottomSheet(
                            context: ctx,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DetailSheet(homework: hw),
                          ),
                          onQuickComplete: () => _handleQuickComplete(hw, familyCode, today),
                        ),
                      ],
                    );
                  },
                  childCount: sorted.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int dDay;
  const _DayHeader({required this.dDay});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.dDayColor(dDay),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              HwDateUtils.dDayGroupLabel(dDay),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.dDayColor(dDay),
              ),
            ),
          ],
        ),
      );
}
