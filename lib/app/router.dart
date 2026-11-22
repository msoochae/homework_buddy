import 'package:flutter/material.dart';
import '../services/local_prefs_service.dart';
import '../features/role_select/role_select_screen.dart';
import '../features/child/child_shell.dart';
import '../features/parent/parent_shell.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const RootNavigator());
      case '/role-select':
        return MaterialPageRoute(builder: (_) => const RoleSelectScreen());
      case '/child':
        return MaterialPageRoute(builder: (_) => const ChildShell());
      case '/parent':
        return MaterialPageRoute(builder: (_) => const ParentShell());
      default:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text('404'))));
    }
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final role = LocalPrefsService.role;
    final familyCode = LocalPrefsService.familyCode;
    if (role == null || familyCode == null) return const RoleSelectScreen();
    if (role.isParent) return const ParentShell();
    return const ChildShell();
  }
}
