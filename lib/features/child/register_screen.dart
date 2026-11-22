import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/hw_date_utils.dart';
import '../../core/due_date_calculator.dart';
import '../../data/models/homework.dart';
import '../../services/local_prefs_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const RegisterScreen({super.key, this.initialDate});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late DateTime _date;
  Category _category = Category.school;
  final _titleController = TextEditingController();
  DateTime? _manualDueDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;
  bool _isNone = false;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  Future<void> _save() async {
    if (!_isNone && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('숙제 제목을 입력하세요')));
      return;
    }
    if (_category == Category.etc && !_isNone && _manualDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기한을 선택하세요')));
      return;
    }
    if (!_isNone && _startTime != null && _endTime != null) {
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin = _endTime!.hour * 60 + _endTime!.minute;
      if (startMin >= endMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시작 시간은 종료 시간보다 앞서야 합니다.')),
        );
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final holidays = ref.read(holidaysProvider).value ?? {};
      final dueDate = _isNone
          ? null
          : (_category == Category.etc
              ? HwDateUtils.toDateString(_manualDueDate!)
              : DueDateCalculator.calculate(_category, _date, holidays));
      final now = DateTime.now();
      final hw = Homework(
        id: const Uuid().v4(),
        date: HwDateUtils.toDateString(_date),
        category: _category.name,
        title: _isNone ? '' : _titleController.text.trim(),
        dueDate: dueDate,
        status: _isNone ? 'none' : 'registered',
        progress: 0,
        createdBy: LocalPrefsService.role?.name ?? 'child',
        createdAt: now,
        updatedAt: now,
        startTime: _isNone || _startTime == null ? null : _formatTime(_startTime!),
        endTime: _isNone || _endTime == null ? null : _formatTime(_endTime!),
      );
      try {
        await ref.read(homeworkRepositoryProvider).add(hw).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firestore add error/timeout: $e');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autodue = ref.watch(holidaysProvider).maybeWhen(
      data: (h) => DueDateCalculator.calculate(_category, _date, h),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('숙제 등록 ✏️')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('등록 날짜'),
              subtitle: Text('${_date.year}/${_date.month}/${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2026),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (p != null) setState(() => _date = p);
              },
            ),
            const Divider(),
            const Text('과목', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Category.values.map((c) => ChoiceChip(
                label: Text('${c.emoji} ${c.displayName}'),
                selected: _category == c,
                onSelected: (_) => setState(() {
                  _category = c;
                  _isNone = false;
                }),
              )).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('📭 숙제 없음'),
              subtitle: const Text('오늘 이 과목은 숙제가 없어요'),
              value: _isNone,
              onChanged: (v) => setState(() => _isNone = v),
            ),
            if (!_isNone) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '숙제 제목',
                  border: OutlineInputBorder(),
                  hintText: '예: 수학 연산 10문제',
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (_category == Category.etc)
                ListTile(
                  title: const Text('기한 선택'),
                  subtitle: Text(_manualDueDate != null
                      ? '${_manualDueDate!.year}/${_manualDueDate!.month}/${_manualDueDate!.day}'
                      : '날짜를 선택하세요'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _manualDueDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: _date,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (p != null) setState(() => _manualDueDate = p);
                  },
                )
              else
                ListTile(
                  title: const Text('자동 계산 기한'),
                  subtitle: Text(autodue?.replaceAll('-', '/') ?? '계산 중...'),
                  leading: const Icon(Icons.alarm, color: Colors.orange),
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
                          Text('수행 시간 관리 (선택)',
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
            ],
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isNone ? '숙제 없음으로 저장' : '숙제 저장'),
              ),
          ],
        ),
      ),
    );
  }
}
