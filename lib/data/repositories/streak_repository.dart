import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/hw_date_utils.dart';

class StreakStats {
  final int streakCount;
  final String lastCompletedDate;
  final int maxStreak;

  const StreakStats({
    this.streakCount = 0,
    this.lastCompletedDate = '',
    this.maxStreak = 0,
  });

  factory StreakStats.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const StreakStats();
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return StreakStats(
      streakCount: d['streakCount'] as int? ?? 0,
      lastCompletedDate: d['lastCompletedDate'] as String? ?? '',
      maxStreak: d['maxStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'streakCount': streakCount,
    'lastCompletedDate': lastCompletedDate,
    'maxStreak': maxStreak,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class PraiseItem {
  final String id;
  final String senderRole;
  final String senderName;
  final String praiseText;
  final String emoji;
  final DateTime createdAt;
  final bool isRead;

  PraiseItem({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.praiseText,
    required this.emoji,
    required this.createdAt,
    this.isRead = false,
  });

  factory PraiseItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PraiseItem(
      id: doc.id,
      senderRole: d['senderRole'] as String? ?? 'dad',
      senderName: d['senderName'] as String? ?? '부모님',
      praiseText: d['praiseText'] as String? ?? '참 잘했어!',
      emoji: d['emoji'] as String? ?? '👏',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }
}

class StreakRepository {
  final FirebaseFirestore _firestore;

  StreakRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _streakDoc(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('streak_data').doc('stats');

  CollectionReference<Map<String, dynamic>> _praiseCol(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('praise_reactions');

  Stream<StreakStats> watchStreak(String familyCode) {
    return _streakDoc(familyCode).snapshots().map((snap) => StreakStats.fromFirestore(snap));
  }

  /// Checks and increments streak if today's requirements are met
  /// Returns bonus tickets granted (e.g. 1 ticket every 7 days), or 0
  Future<int> checkAndIncrementStreak(String familyCode, String todayStr) async {
    final docRef = _streakDoc(familyCode);
    final snap = await docRef.get();
    final current = snap.exists ? StreakStats.fromFirestore(snap) : const StreakStats();

    if (current.lastCompletedDate == todayStr) {
      return 0; // Already registered streak for today
    }

    final today = DateTime.parse(todayStr);
    final yesterdayStr = HwDateUtils.toDateString(today.subtract(const Duration(days: 1)));

    int newStreak;
    if (current.lastCompletedDate == yesterdayStr) {
      newStreak = current.streakCount + 1;
    } else {
      // Missed at least one day or first time
      newStreak = 1;
    }

    final newMax = newStreak > current.maxStreak ? newStreak : current.maxStreak;
    await docRef.set({
      'streakCount': newStreak,
      'lastCompletedDate': todayStr,
      'maxStreak': newMax,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Bonus ticket on 7th, 14th, 21st, etc.
    if (newStreak > 0 && newStreak % 7 == 0) {
      final ticketsRef = _firestore
          .collection('families')
          .doc(familyCode)
          .collection('lottery_data')
          .doc('tickets');
      await ticketsRef.set({
        'count': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return 1;
    }

    return 0;
  }

  // Real-time Praise / High-Five
  Stream<List<PraiseItem>> watchUnreadPraises(String familyCode) {
    return _praiseCol(familyCode)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => PraiseItem.fromFirestore(doc)).toList());
  }

  Future<void> sendPraise({
    required String familyCode,
    required String senderRole,
    required String senderName,
    required String praiseText,
    required String emoji,
  }) async {
    await _praiseCol(familyCode).add({
      'senderRole': senderRole,
      'senderName': senderName,
      'praiseText': praiseText,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> markPraiseAsRead(String familyCode, String praiseId) async {
    await _praiseCol(familyCode).doc(praiseId).update({'isRead': true});
  }
}
