import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/repositories/family_repository.dart';
import '../../services/fcm_service.dart';
import '../../services/local_prefs_service.dart';
import 'family_code_screen.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _loading = false;

  Future<void> _selectRole(UserRole role) async {
    if (role.isParent) {
      final pin = await _askPin();
      if (pin != AppConstants.parentPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN이 올바르지 않아요')),
          );
        }
        return;
      }
    }
    setState(() => _loading = true);
    await LocalPrefsService.setRole(role);

    if (LocalPrefsService.familyCode == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FamilyCodeScreen()),
        );
      }
      return;
    }

    final code = LocalPrefsService.familyCode!;
    ref.read(familyCodeProvider.notifier).state = code;

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firebase Auth error: $e');
    }

    try {
      final token = await FcmService.getToken();
      if (token != null) {
        await FamilyRepository().saveDevice(
          code,
          LocalPrefsService.deviceId,
          role.name,
          token,
        ).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Device token save error: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        role.isParent ? '/parent' : '/child',
      );
    }
    setState(() => _loading = false);
  }

  Future<String> _askPin() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('부모 PIN 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: '4자리 PIN', counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('숙제버디 📚', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('이 기기에서 사용할 역할을 선택하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _roleBtn('🧒', '채이현 (아이)', Colors.green, () => _selectRole(UserRole.child)),
                const SizedBox(height: 16),
                _roleBtn('👨', '아빠', Colors.blue, () => _selectRole(UserRole.dad)),
                const SizedBox(height: 16),
                _roleBtn('👩', '엄마', Colors.pink, () => _selectRole(UserRole.mom)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String emoji, String label, Color color, VoidCallback onTap) =>
      SizedBox(
        height: 80,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: color),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
