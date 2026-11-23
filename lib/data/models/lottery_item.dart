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
    LotteryPrize(rank: 1, probability: 0.5, title: '1등', reward: '금액 5만원권 💵', emoji: '👑'),
    LotteryPrize(rank: 2, probability: 2.5, title: '2등', reward: '낚시까페 1시간 🎣', emoji: '🎣'),
    LotteryPrize(rank: 3, probability: 5.0, title: '3등', reward: '보석 1만원권 💎', emoji: '💎'),
    LotteryPrize(rank: 4, probability: 12.0, title: '4등', reward: '게임 5분 🎮', emoji: '🎮'),
    LotteryPrize(rank: 5, probability: 15.0, title: '5등', reward: '놀아주기 10분 🧸', emoji: '🧸'),
    LotteryPrize(rank: 6, probability: 25.0, title: '6등', reward: '금액 500원권 🪙', emoji: '🪙'),
    LotteryPrize(rank: 7, probability: 40.0, title: '7등', reward: '편의점 200원권 🏪', emoji: '🏪'),
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
