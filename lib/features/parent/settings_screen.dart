import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/hw_date_utils.dart';
import '../../data/repositories/family_repository.dart';
import '../../services/local_prefs_service.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  bool _notif = LocalPrefsService.notificationsEnabled;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('설정 ⚙️'),
    ),
    body: ListView(
      children: [
        ListTile(
          title: const Text('가족 코드'),
          subtitle: Text(LocalPrefsService.familyCode ?? '없음'),
          leading: const Icon(Icons.family_restroom),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('알림 받기'),
          subtitle: const Text('푸시 알림 및 리마인더'),
          secondary: const Icon(Icons.notifications),
          value: _notif,
          onChanged: (v) async {
            await LocalPrefsService.setNotificationsEnabled(v);
            setState(() => _notif = v);
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('방학/재량휴업일 추가'),
          subtitle: const Text('학교 영업일 계산에서 제외할 날짜 추가'),
          leading: const Icon(Icons.beach_access),
          trailing: const Icon(Icons.chevron_right),
          onTap: _addHoliday,
        ),
        if (LocalPrefsService.isParent) ...[
          const Divider(),
          ListTile(
            title: const Text('역할 변경'),
            subtitle: const Text('아이 화면 또는 다른 부모 역할로 전환'),
            leading: const Icon(Icons.swap_horiz),
            onTap: () => Navigator.pushReplacementNamed(context, '/role-select'),
          ),
        ],
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '숙제버디 v1.0.0\n채이현이를 위한 가족 숙제 관리 앱',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Future<void> _addHoliday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2028, 12, 31),
      helpText: '방학/재량휴업일 선택',
    );
    if (picked == null) return;
    final code = LocalPrefsService.familyCode;
    if (code == null) return;
    try {
      await FamilyRepository().addHoliday(code, HwDateUtils.toDateString(picked)).timeout(const Duration(seconds: 4));
      ref.invalidate(holidaysProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${picked.month}/${picked.day} 휴일이 추가되었어요')),
        );
      }
    } catch (e) {
      debugPrint('addHoliday error/timeout: $e');
    }
  }
}
