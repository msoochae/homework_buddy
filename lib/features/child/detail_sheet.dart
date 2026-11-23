import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/hw_date_utils.dart';
import '../../data/models/homework.dart';
import '../shared/pomodoro_timer_sheet.dart';

class DetailSheet extends ConsumerStatefulWidget {
  final Homework homework;
  const DetailSheet({super.key, required this.homework});

  @override
  ConsumerState<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<DetailSheet> {
  late int _progress;
  late String _status;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.homework.progress;
    _status = widget.homework.status;
    _startTime = _parseTime(widget.homework.startTime);
    _endTime = _parseTime(widget.homework.endTime);
  }

  static TimeOfDay? _parseTime(String? s) {
    if (s == null || !s.contains(':')) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _onProgressChanged(double v) {
    final p = (v * 10).round() * 10;
    setState(() {
      _progress = p;
      if (p == 0) {
        _status = 'registered';
      } else if (p == 100) {
        _status = 'done';
      } else {
        _status = 'in_progress';
      }
    });
  }

  Future<void> _save() async {
    if (_startTime != null && _endTime != null) {
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin = _endTime!.hour * 60 + _endTime!.minute;
      if (startMin >= endMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시작 시간은 종료 시간보다 앞서야 합니다.')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final updated = widget.homework.copyWith(
        progress: _progress,
        status: _status,
        updatedAt: now,
        completedAt: _status == 'done' ? now : null,
        clearCompletedAt: _status != 'done',
        startTime: _startTime != null ? _formatTime(_startTime!) : null,
        endTime: _endTime != null ? _formatTime(_endTime!) : null,
        clearTimes: _startTime == null && _endTime == null,
      );
      try {
        await ref.read(homeworkRepositoryProvider).update(updated).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firestore update error/timeout: $e');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 숙제를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(homeworkRepositoryProvider).delete(widget.homework.id).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firestore delete error/timeout: $e');
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hw = widget.homework;
    final cat = Category.values.firstWhere((c) => c.name == hw.category, orElse: () => Category.etc);
    final dDay = hw.dDay;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                  Row(
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hw.title.isEmpty ? '숙제 없음' : hw.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(cat.displayName, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hw.dueDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.dDayColor(dDay).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dDayColor(dDay)),
                      ),
                      child: Text(
                        '기한: ${hw.dueDate!.replaceAll('-', '/')}  (${HwDateUtils.dDayLabel(dDay)})',
                        style: TextStyle(color: AppTheme.dDayColor(dDay), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (hw.status != 'none') ...[
                    Text('진행률: $_progress%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _progress / 100,
                      divisions: 10,
                      label: '$_progress%',
                      onChanged: _saving ? null : _onProgressChanged,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          PomodoroTimerSheet.show(context, widget.homework);
                        },
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: const Text('⏱️ 집중 뽀모도로 타이머 시작'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('상태: '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusColor(_status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            HomeworkStatus.fromCode(_status).displayName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.blueGrey.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.schedule, size: 20, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('수행 시간 관리',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final t = await showTimePicker(
                                        context: context,
                                        initialTime: _startTime ?? const TimeOfDay(hour: 15, minute: 0),
                                      );
                                      if (t != null) setState(() => _startTime = t);
                                    },
                                    icon: const Icon(Icons.play_arrow, size: 18),
                                    label: Text(_startTime == null
                                        ? '시작 시간'
                                        : '시작 ${_formatTime(_startTime!)}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final t = await showTimePicker(
                                        context: context,
                                        initialTime: _endTime ?? const TimeOfDay(hour: 16, minute: 0),
                                      );
                                      if (t != null) setState(() => _endTime = t);
                                    },
                                    icon: const Icon(Icons.stop, size: 18),
                                    label: Text(_endTime == null
                                        ? '종료 시간'
                                        : '종료 ${_formatTime(_endTime!)}'),
                                  ),
                                ),
                                if (_startTime != null || _endTime != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    tooltip: '시간 초기화',
                                    onPressed: () => setState(() {
                                      _startTime = null;
                                      _endTime = null;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_saving)
                      const Center(child: CircularProgressIndicator())
                    else
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('저장'),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
