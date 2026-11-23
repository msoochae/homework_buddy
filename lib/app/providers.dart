import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/homework.dart';
import '../data/models/lottery_item.dart';
import '../data/models/chat_message.dart';
import '../data/repositories/homework_repository.dart';
import '../data/repositories/family_repository.dart';
import '../data/repositories/lottery_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/streak_repository.dart';
import '../services/local_prefs_service.dart';

final familyCodeProvider = StateProvider<String>((ref) {
  return LocalPrefsService.familyCode ?? '';
});

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  final code = ref.watch(familyCodeProvider);
  return HomeworkRepository(familyCode: code);
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

final lotteryRepositoryProvider = Provider<LotteryRepository>((ref) {
  return LotteryRepository(FirebaseFirestore.instance);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepository(FirebaseFirestore.instance);
});

final streakStatsProvider = StreamProvider<StreakStats>((ref) {
  final code = ref.watch(familyCodeProvider);
  if (code.isEmpty) return Stream.value(const StreakStats());
  return ref.watch(streakRepositoryProvider).watchStreak(code);
});

final unreadPraisesProvider = StreamProvider<List<PraiseItem>>((ref) {
  final code = ref.watch(familyCodeProvider);
  if (code.isEmpty) return Stream.value([]);
  return ref.watch(streakRepositoryProvider).watchUnreadPraises(code);
});

final lotteryTicketsProvider = StreamProvider<int>((ref) {
  final code = ref.watch(familyCodeProvider);
  if (code.isEmpty) return Stream.value(0);
  return ref.watch(lotteryRepositoryProvider).watchTickets(code);
});

final lotteryInventoryProvider = StreamProvider<List<LotteryInventoryItem>>((ref) {
  final code = ref.watch(familyCodeProvider);
  if (code.isEmpty) return Stream.value([]);
  return ref.watch(lotteryRepositoryProvider).watchInventory(code);
});

final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final code = ref.watch(familyCodeProvider);
  if (code.isEmpty) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchMessages(code);
});

final bundledHolidaysProvider = FutureProvider<Set<String>>((ref) async {
  final json = await rootBundle.loadString('assets/holidays_kr.json');
  final data = jsonDecode(json) as Map<String, dynamic>;
  return Set<String>.from(data['holidays'] as List);
});

final holidaysProvider = FutureProvider<Set<String>>((ref) async {
  final bundled = await ref.watch(bundledHolidaysProvider.future);
  final familyCode = ref.watch(familyCodeProvider);
  if (familyCode.isEmpty) return bundled;
  try {
    final repo = ref.watch(familyRepositoryProvider);
    final custom = await repo.getHolidays(familyCode);
    return bundled.union(custom);
  } catch (_) {
    return bundled;
  }
});

final homeworksByDateProvider = StreamProvider.family<List<Homework>, String>((ref, date) {
  final repo = ref.watch(homeworkRepositoryProvider);
  return repo.watchByDate(date);
});

final activeAndTodayHomeworksProvider = StreamProvider.family<List<Homework>, String>((ref, today) {
  final repo = ref.watch(homeworkRepositoryProvider);
  return repo.watchActiveAndToday(today);
});

final homeworksRangeProvider = StreamProvider.family<List<Homework>, (String, String)>((ref, range) {
  final repo = ref.watch(homeworkRepositoryProvider);
  return repo.watchRange(range.$1, range.$2);
});
