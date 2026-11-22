import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'calendar_tab.dart';

class ChildHomeworkView extends StatefulWidget {
  const ChildHomeworkView({super.key});

  @override
  State<ChildHomeworkView> createState() => _ChildHomeworkViewState();
}

class _ChildHomeworkViewState extends State<ChildHomeworkView> {
  int _viewIndex = 0; // 0: 오늘, 1: 달력

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF5B5FEF),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B95A1),
                  side: const BorderSide(color: Color(0xFFF2F4F6), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    icon: Icon(Icons.today, size: 18),
                    label: Text('오늘의 숙제'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.calendar_month, size: 18),
                    label: Text('달력 보기'),
                  ),
                ],
                selected: {_viewIndex},
                onSelectionChanged: (newSelection) {
                  setState(() => _viewIndex = newSelection.first);
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _viewIndex,
            children: const [
              HomeTab(),
              CalendarTab(),
            ],
          ),
        ),
      ],
    );
  }
}
