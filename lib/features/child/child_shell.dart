import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import 'child_homework_view.dart';
import 'register_screen.dart';
import '../lottery/lottery_screen.dart';
import '../chat/chat_screen.dart';

class ChildShell extends ConsumerStatefulWidget {
  const ChildShell({super.key});

  @override
  ConsumerState<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends ConsumerState<ChildShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final familyCode = ref.watch(familyCodeProvider);

    return Scaffold(
      appBar: _tab == 0
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('채이현의 숙제버디 👧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: const [
          ChildHomeworkView(),
          LotteryScreen(),
          ChatScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '숙제',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: '뽑기',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text('숙제 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          : null,
    );
  }
}
