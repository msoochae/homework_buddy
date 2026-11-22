import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/hw_date_utils.dart';
import '../../data/models/homework.dart';
import 'pomodoro_timer_sheet.dart';

class HomeworkCard extends StatelessWidget {
  final Homework hw;
  final VoidCallback onTap;
  final VoidCallback? onQuickComplete;

  const HomeworkCard({
    super.key,
    required this.hw,
    required this.onTap,
    this.onQuickComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = Category.values.firstWhere(
      (c) => c.name == hw.category,
      orElse: () => Category.etc,
    );
    final isDone = hw.status == 'done';
    final isNone = hw.status == 'none';
    final catColor = AppTheme.categoryColor(cat);

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? const Color(0xFFEEEEEE) : AppTheme.border,
          width: 1.2,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF191F28).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pastel category circle
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),

                    // Title, category, time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cat.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppTheme.textSecondary : catColor,
                                ),
                              ),
                              if (!isNone && hw.dueDate != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dDayBgColor(hw.dDay),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    HwDateUtils.dDayLabel(hw.dDay),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.dDayColor(hw.dDay),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isNone ? '숙제 없음' : (hw.title.isEmpty ? '(제목 없음)' : hw.title),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isNone && hw.timeRangeText != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 13, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  hw.timeRangeText!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Pomodoro Timer trigger
                    if (!isNone && !isDone)
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 22),
                        tooltip: '집중 뽀모도로 타이머',
                        onPressed: () => PomodoroTimerSheet.show(context, hw),
                      ),

                    // Complete Check circle
                    if (!isNone)
                      GestureDetector(
                        onTap: () {
                          if (!isDone && onQuickComplete != null) {
                            HapticFeedback.mediumImpact();
                            onQuickComplete!();
                          } else {
                            onTap();
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? AppTheme.success : Colors.transparent,
                            border: Border.all(
                              color: isDone ? AppTheme.success : const Color(0xFFD1D6DB),
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),

                // Progress Bar
                if (!isNone && hw.status == 'in_progress') ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: hw.progress / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.border,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // If active, wrap with Dismissible for swipe-to-complete with haptic feedback
    if (!isDone && !isNone && onQuickComplete != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Dismissible(
          key: ValueKey('swipe_${hw.id}_${hw.status}'),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (dir) async {
            HapticFeedback.mediumImpact();
            onQuickComplete!();
            return false; // don't remove from widget tree immediately; state will refresh
          },
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  '완료! 🎉',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          child: cardBody,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: cardBody,
    );
  }
}
