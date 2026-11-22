import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryPrize {
  final int rank;
  final double probability;
  final String title;
  final String reward;
  final String emoji;

  const LotteryPrize({
    required this.rank,
    required this.probability,
    required this.title,
    required this.reward,
    required this.emoji,
  });

  static const List<LotteryPrize> prizes = [
    LotteryPrize(rank: 1, probability: 0.5, title: '1등', reward: '대박 소원권 🌟', emoji: '👑'),
    LotteryPrize(rank: 2, probability: 2.0, title: '2등', reward: '특급 선물 / 용돈 🎁', emoji: '💎'),
    LotteryPrize(rank: 3, probability: 4.0, title: '3등', reward: '자유시간 1시간 🎮', emoji: '🥇'),
    LotteryPrize(rank: 4, probability: 7.5, title: '4등', reward: '맛있는 간식 세트 🍦', emoji: '🥈'),
    LotteryPrize(rank: 5, probability: 10.0, title: '5등', reward: '숙제 10분 쉬기 ☕', emoji: '🥉'),
    LotteryPrize(rank: 6, probability: 20.0, title: '6등', reward: '달콤한 사탕 / 초콜릿 🍬', emoji: '🍭'),
    LotteryPrize(rank: 7, probability: 56.0, title: '7등', reward: '따뜻한 칭찬과 포옹 ❤️', emoji: '💖'),
  ];
}

class LotteryInventoryItem {
  final String id;
  final int rank;
  final String reward;
  final String emoji;
  final DateTime wonAt;
  final bool isUsed;

  LotteryInventoryItem({
    required this.id,
    required this.rank,
    required this.reward,
    required this.emoji,
    required this.wonAt,
    this.isUsed = false,
  });

  factory LotteryInventoryItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return LotteryInventoryItem(
      id: doc.id,
      rank: d['rank'] as int? ?? 7,
      reward: d['reward'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '🎁',
      wonAt: (d['wonAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUsed: d['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'rank': rank,
    'reward': reward,
    'emoji': emoji,
    'wonAt': Timestamp.fromDate(wonAt),
    'isUsed': isUsed,
  };
}
