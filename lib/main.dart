import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'services/fcm_service.dart';
import 'services/local_prefs_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  await LocalPrefsService.init();
  try {
    await NotificationService.init();
    await NotificationService.requestPermission();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  try {
    await FcmService.init();
  } catch (e) {
    debugPrint('FCM init error: $e');
  }
  runApp(const ProviderScope(child: HomeworkBuddyApp()));
}

class HomeworkBuddyApp extends StatelessWidget {
  const HomeworkBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '숙제버디',
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      debugShowCheckedModeBanner: false,
    );
  }
}
