import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/registration_checker.dart';
import '../../data/models/homework.dart';

class UnregisteredBanner extends ConsumerWidget {
  final List<Homework> homeworks;
  final DateTime date;
  const UnregisteredBanner({super.key, required this.homeworks, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (RegistrationChecker.isFutureDate(date)) return const SizedBox.shrink();
    return ref.watch(holidaysProvider).maybeWhen(
      data: (holidays) {
        final missing = <Category>[];
        for (final cat in [Category.school, Category.english, Category.math]) {
          if (!RegistrationChecker.isRequiredDay(cat, date, holidays)) continue;
          if (!homeworks.any((h) => h.category == cat.name)) missing.add(cat);
        }
        if (missing.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD4D4), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B4B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '오늘 미등록 과목: ${missing.map((c) => c.displayName).join(', ')}',
                  style: const TextStyle(
                    color: Color(0xFFFF4B4B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
