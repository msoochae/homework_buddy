import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/hw_date_utils.dart';
import '../../core/registration_checker.dart';
import '../../core/priority_sorter.dart';
import '../../data/models/homework.dart';
import '../child/calendar_tab.dart';
import 'notification_history_tab.dart';
import 'settings_screen.dart';
import '../../services/local_prefs_service.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = HwDateUtils.toDateString(DateTime.now());
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekStart = HwDateUtils.toDateString(monday);
    final weekEnd = HwDateUtils.toDateString(sunday);

    final todayAsync = ref.watch(homeworksByDateProvider(today));
    final activeAndTodayAsync = ref.watch(activeAndTodayHomeworksProvider(today));
    final weekAsync = ref.watch(homeworksRangeProvider((weekStart, weekEnd)));
    final holidaysAsync = ref.watch(holidaysProvider);
    final familyCode = ref.watch(familyCodeProvider);

    return CustomScrollView(slivers: [
      SliverAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('부모 대시보드 👨‍👩‍👧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              familyCode.isNotEmpty ? '가족코드: $familyCode' : '가족코드 연결 필요',
              style: TextStyle(
                fontSize: 11,
                color: familyCode.isNotEmpty ? Colors.black54 : Colors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        floating: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '달력 조회',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('숙제 달력 📅')),
                  body: const CalendarTab(showAppBar: false),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '알림 내역',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationHistoryTab()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParentSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(homeworksByDateProvider(today));
              ref.invalidate(homeworksRangeProvider((weekStart, weekEnd)));
            },
          ),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([
          // Today status
          todayAsync.when(
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
            error: (e, _) => Text('오류: $e'),
            data: (hw) => holidaysAsync.maybeWhen(
              data: (hol) => _TodayStatusCard(homeworks: hw, date: now, holidays: hol),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
          // Quick Praise High-Five Card for Parents
          _ParentPraiseQuickCard(familyCode: familyCode),
          const SizedBox(height: 16),
          // Weekly progress
          weekAsync.when(
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
            error: (e, _) => Text('오류: $e'),
            data: (hw) => _WeeklyProgressCard(homeworks: hw),
          ),
          const SizedBox(height: 16),
          // Today's Individual Homeworks & Active Homeworks
          activeAndTodayAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (hw) => _TodayIndividualHomeworksCard(homeworks: hw),
          ),
          const SizedBox(height: 16),
          // Urgent (includes all active overdue and today's due homeworks)
          activeAndTodayAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (hw) {
              final urgent = PrioritySorter.sort(hw).where((h) => HwDateUtils.isUrgent(h.dDay)).toList();
              return urgent.isEmpty ? const SizedBox.shrink() : _UrgentCard(homeworks: urgent);
            },
          ),
          const SizedBox(height: 16),
          // Recent
          weekAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (hw) => _RecentChangesCard(homeworks: hw),
          ),
        ])),
      ),
    ]);
  }
}

class _TodayStatusCard extends StatelessWidget {
  final List<Homework> homeworks;
  final DateTime date;
  final Set<String> holidays;
  const _TodayStatusCard({required this.homeworks, required this.date, required this.holidays});

  @override
  Widget build(BuildContext context) {
    final cats = [Category.school, Category.english, Category.math];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.today, color: Colors.blue),
          const SizedBox(width: 8),
          Text('오늘 등록 현황 (${date.month}/${date.day})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        ...cats.map((cat) {
          if (!RegistrationChecker.isRequiredDay(cat, date, holidays)) return const SizedBox.shrink();
          final catHw = homeworks.where((h) => h.category == cat.name).toList();
          final hasNone = catHw.any((h) => h.status == 'none');
          final hasReg = catHw.any((h) => h.status != 'none');
          String txt; Color col; IconData icon;
          if (hasNone) { txt = '숙제 없음'; col = Colors.grey; icon = Icons.check_circle_outline; }
          else if (hasReg) {
            final done = catHw.where((h) => h.status == 'done').length;
            txt = '$done/${catHw.length}개 완료';
            col = done == catHw.length ? Colors.green : Colors.orange;
            icon = done == catHw.length ? Icons.check_circle : Icons.pending;
          } else { txt = '미등록 ⚠️'; col = Colors.red; icon = Icons.warning; }
          return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(cat.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Icon(icon, color: col, size: 16),
              const SizedBox(width: 4),
              Text(txt, style: TextStyle(color: col)),
            ]),
          );
        }),
      ],
    )));
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  final List<Homework> homeworks;
  const _WeeklyProgressCard({required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final active = homeworks.where((h) => h.status != 'none').toList();
    if (active.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('이번 주 등록된 숙제가 없어요')));
    final avg = active.fold(0, (s, h) => s + h.progress) / active.length;
    final done = active.where((h) => h.status == 'done').length;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.bar_chart, color: Colors.green),
          SizedBox(width: 8),
          Text('이번 주 진척률', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: avg / 100, minHeight: 12, borderRadius: BorderRadius.circular(6)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('평균 ${avg.round()}%', style: const TextStyle(fontSize: 16)),
          Text('$done/${active.length}개 완료', style: const TextStyle(color: Colors.grey)),
        ]),
      ],
    )));
  }
}

class _UrgentCard extends StatelessWidget {
  final List<Homework> homeworks;
  const _UrgentCard({required this.homeworks});

  @override
  Widget build(BuildContext context) {
    return Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.alarm, color: Colors.red),
          SizedBox(width: 8),
          Text('임박/지연 숙제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
        const SizedBox(height: 8),
        ...homeworks.map((hw) {
          final cat = Category.values.firstWhere((c) => c.name == hw.category, orElse: () => Category.etc);
          return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text(cat.emoji),
              const SizedBox(width: 8),
              Expanded(child: Text(hw.title.isEmpty ? '(제목 없음)' : hw.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.dDayColor(hw.dDay), borderRadius: BorderRadius.circular(8)),
                child: Text(HwDateUtils.dDayLabel(hw.dDay), style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ]),
          );
        }),
      ],
    )));
  }
}

class _RecentChangesCard extends StatelessWidget {
  final List<Homework> homeworks;
  const _RecentChangesCard({required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final recent = ([...homeworks]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.history, color: Colors.purple),
          SizedBox(width: 8),
          Text('최근 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ...recent.map((hw) {
          final cat = Category.values.firstWhere((c) => c.name == hw.category, orElse: () => Category.etc);
          final diff = DateTime.now().difference(hw.updatedAt);
          final timeStr = diff.inMinutes < 1 ? '방금' : diff.inMinutes < 60 ? '${diff.inMinutes}분 전' : diff.inHours < 24 ? '${diff.inHours}시간 전' : '${diff.inDays}일 전';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(hw.title.isEmpty ? '숙제 없음' : hw.title),
            subtitle: Text('${cat.displayName} · ${HomeworkStatus.fromCode(hw.status).displayName}'),
            trailing: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }),
      ],
    )));
  }
}

class _ParentPraiseQuickCard extends ConsumerWidget {
  final String familyCode;
  const _ParentPraiseQuickCard({required this.familyCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Soft warm pastel yellow
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECB3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('👏', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                '이현이에게 칭찬 하이파이브 보내기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ('👏', '참 잘했어!'),
                ('❤️', '최고야!'),
                ('🌟', '대단해!'),
                ('🍦', '간식타임!'),
                ('🎮', '자유시간!'),
              ].map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonal(
                  onPressed: () async {
                    final role = LocalPrefsService.role?.name ?? 'dad';
                    final senderName = role == 'mom' ? '엄마' : '아빠';
                    await ref.read(streakRepositoryProvider).sendPraise(
                      familyCode: familyCode,
                      senderRole: role,
                      senderName: senderName,
                      praiseText: p.$2,
                      emoji: p.$1,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('이현이에게 \'${p.$2}\' 칭찬을 보냈습니다! ✨')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5D4037),
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.$1),
                      const SizedBox(width: 4),
                      Text(p.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayIndividualHomeworksCard extends StatelessWidget {
  final List<Homework> homeworks;
  const _TodayIndividualHomeworksCard({required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final active = homeworks.where((h) => h.status != 'none').toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rtl_rounded, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  '오늘의 숙제 현황 (${active.length}건)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('오늘 등록된 숙제가 없습니다.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...active.map((hw) {
                final cat = Category.values.firstWhere(
                  (c) => c.name == hw.category,
                  orElse: () => Category.etc,
                );
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hw.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.statusColor(hw.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              HomeworkStatus.fromCode(hw.status).displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (hw.timeRangeText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              hw.timeRangeText!,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: hw.progress / 100,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${hw.progress}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
