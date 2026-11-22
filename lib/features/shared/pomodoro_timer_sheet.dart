import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/models/homework.dart';

class PomodoroTimerSheet extends ConsumerStatefulWidget {
  final Homework homework;

  const PomodoroTimerSheet({super.key, required this.homework});

  static void show(BuildContext context, Homework hw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PomodoroTimerSheet(homework: hw),
    );
  }

  @override
  ConsumerState<PomodoroTimerSheet> createState() => _PomodoroTimerSheetState();
}

class _PomodoroTimerSheetState extends ConsumerState<PomodoroTimerSheet> {
  int _targetMinutes = 25;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _targetMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setMinutes(int mins) {
    if (_isRunning) return;
    setState(() {
      _targetMinutes = mins;
      _remainingSeconds = mins * 60;
    });
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          t.cancel();
          _onTimerComplete();
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _targetMinutes * 60;
    });
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    setState(() => _isRunning = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 집중 완료! 대단해요!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '\'${widget.homework.title}\' 숙제를\n$_targetMinutes분 동안 멋지게 집중했어요!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('진행 상태를 어떻게 변경할까요?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('나중에'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = widget.homework.copyWith(
                progress: 50,
                status: 'in_progress',
                updatedAt: DateTime.now(),
              );
              await ref.read(homeworkRepositoryProvider).update(updated);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('50% 진행'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final updated = widget.homework.copyWith(
                progress: 100,
                status: 'done',
                updatedAt: now,
                completedAt: now,
              );
              await ref.read(homeworkRepositoryProvider).update(updated);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('100% 완료 🎉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = 1.0 - (_remainingSeconds / (_targetMinutes * 60));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '뽀모도로 집중 타이머',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            widget.homework.title.isEmpty ? '숙제에 집중해보세요' : widget.homework.title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Quick Minute Selectors
          if (!_isRunning) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [10, 15, 20, 25, 30, 45, 60].map((m) {
                  final isSelected = _targetMinutes == m;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$m분'),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _setMinutes(m),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Circular countdown timer
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.border,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _isRunning ? '집중 중... 🔥' : '준비 완료 ✨',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isRunning ? AppTheme.secondary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 28,
                tooltip: '리셋',
              ),
              const SizedBox(width: 24),
              FilledButton.icon(
                onPressed: _toggleTimer,
                style: FilledButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.amber.shade800 : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                label: Text(
                  _isRunning ? '일시정지' : '시작하기',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
