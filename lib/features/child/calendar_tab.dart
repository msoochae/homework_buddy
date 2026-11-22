import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../app/providers.dart';
import '../../core/hw_date_utils.dart';
import '../../core/constants.dart';
import '../../core/registration_checker.dart';
import '../../data/models/homework.dart';
import '../shared/homework_card.dart';
import 'detail_sheet.dart';
import 'register_screen.dart';

class CalendarTab extends ConsumerStatefulWidget {
  final bool showAppBar;
  const CalendarTab({super.key, this.showAppBar = true});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  String get _selectedStr => HwDateUtils.toDateString(_selected);

  @override
  Widget build(BuildContext context) {
    final monthStart = HwDateUtils.toDateString(DateTime(_focused.year, _focused.month, 1));
    final monthEnd = HwDateUtils.toDateString(DateTime(_focused.year, _focused.month + 1, 0));
    final monthAsync = ref.watch(homeworksRangeProvider((monthStart, monthEnd)));
    final dayAsync = ref.watch(homeworksByDateProvider(_selectedStr));
    final holidaysAsync = ref.watch(holidaysProvider);

    return Column(
      children: [
        if (widget.showAppBar)
          AppBar(
            title: const Text('달력 📅'),
            automaticallyImplyLeading: false,
          ),
        monthAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (mh) => holidaysAsync.maybeWhen(
            data: (h) => _buildCalendar(mh, h),
            orElse: () => _buildCalendar(mh, {}),
          ),
        ),
        const Divider(),
        Expanded(
          child: dayAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: _buildDayList,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(List<Homework> mh, Set<String> holidays) {
    final Map<String, List<Homework>> byDate = {};
    for (final hw in mh) {
      byDate.putIfAbsent(hw.date, () => []).add(hw);
    }

    return TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime(2026, 1, 1),
      lastDay: DateTime(2027, 12, 31),
      focusedDay: _focused,
      selectedDayPredicate: (d) => isSameDay(d, _selected),
      onDaySelected: (sel, foc) => setState(() {
        _selected = sel;
        _focused = foc;
      }),
      onPageChanged: (foc) => setState(() => _focused = foc),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (ctx, day, _) {
          final dateStr = HwDateUtils.toDateString(day);
          final dayHw = byDate[dateStr] ?? [];
          final today = DateTime.now();
          final isPast = !day.isAfter(DateTime(today.year, today.month, today.day));
          if (dayHw.isEmpty && isPast) {
            final hasRequired = Category.values
                .where((c) => c != Category.etc)
                .any((c) => RegistrationChecker.isRequiredDay(c, day, holidays));
            if (!hasRequired) return null;
            return Positioned(bottom: 1, child: _dot(Colors.red));
          }
          if (dayHw.isNotEmpty) {
            final allReg = Category.values
                .where((c) => c != Category.etc)
                .every((c) =>
                    !RegistrationChecker.isRequiredDay(c, day, holidays) ||
                    dayHw.any((h) => h.category == c.name));
            return Positioned(bottom: 1, child: _dot(allReg ? Colors.green : Colors.orange));
          }
          return null;
        },
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildDayList(List<Homework> homeworks) {
    if (homeworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_selected.month}/${_selected.day} 등록된 숙제가 없어요',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen(initialDate: _selected)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('숙제 등록'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: homeworks.length,
      itemBuilder: (ctx, i) => HomeworkCard(
        hw: homeworks[i],
        onTap: () => showModalBottomSheet(
          context: ctx,
          isScrollControlled: true,
          builder: (_) => DetailSheet(homework: homeworks[i]),
        ),
      ),
    );
  }
}
