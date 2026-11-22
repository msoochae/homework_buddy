import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/repositories/family_repository.dart';
import '../../services/fcm_service.dart';
import '../../services/local_prefs_service.dart';

class FamilyCodeScreen extends StatefulWidget {
  const FamilyCodeScreen({super.key});

  @override
  State<FamilyCodeScreen> createState() => _FamilyCodeScreenState();
}

class _FamilyCodeScreenState extends State<FamilyCodeScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  void _syncDeviceInBackground(String code, UserRole role) {
    Future(() async {
      try {
        await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firebase Auth background error: $e');
      }

      try {
        final token = await FcmService.getToken();
        if (token != null) {
          await FamilyRepository()
              .saveDevice(code, LocalPrefsService.deviceId, role.name, token)
              .timeout(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('Device token save background error: $e');
      }
    });
  }

  Future<void> _join() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = '6자리 코드를 입력하세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await LocalPrefsService.setFamilyCode(code);
      final role = LocalPrefsService.role ?? UserRole.child;

      _syncDeviceInBackground(code, role);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(role.isParent ? '/parent' : '/child');
      }
    } catch (e) {
      setState(() => _error = '연결 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final code = FamilyRepository.generateFamilyCode();
      await LocalPrefsService.setFamilyCode(code);
      final role = LocalPrefsService.role ?? UserRole.child;

      _syncDeviceInBackground(code, role);

      if (mounted) {
        setState(() => _loading = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('가족 코드 생성 완료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('다른 가족 기기에서 이 코드를 입력하세요:'),
                const SizedBox(height: 16),
                Text(
                  code,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 8),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(role.isParent ? '/parent' : '/child');
        }
      }
    } catch (e) {
      setState(() => _error = '생성 오류: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('가족 코드 설정')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '가족 코드로 연결하면\n모든 기기에서 숙제를 함께 볼 수 있어요',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 8),
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '6자리 가족 코드',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton(onPressed: _join, child: const Text('코드로 참여하기')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _create, child: const Text('새 가족 코드 만들기')),
          ],
        ],
      ),
    ),
  );
}
