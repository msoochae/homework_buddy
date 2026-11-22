import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lottery_item.dart';

class LotteryRepository {
  final FirebaseFirestore _firestore;

  LotteryRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _ticketsDoc(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('lottery_data').doc('tickets');

  CollectionReference<Map<String, dynamic>> _inventoryCol(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('lottery_inventory');

  Stream<int> watchTickets(String familyCode) {
    return _ticketsDoc(familyCode).snapshots().map((snap) {
      if (!snap.exists) return 0;
      final data = snap.data();
      return (data?['count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> addTickets(String familyCode, int count) async {
    await _ticketsDoc(familyCode).set({
      'count': FieldValue.increment(count),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<LotteryPrize> draw(String familyCode) async {
    final ticketsRef = _ticketsDoc(familyCode);
    final inventoryRef = _inventoryCol(familyCode);

    // Pick prize based on probability distribution:
    // 1등: 0.5% (0.0 ~ < 0.5)
    // 2등: 2.0% (0.5 ~ < 2.5)
    // 3등: 4.0% (2.5 ~ < 6.5)
    // 4등: 7.5% (6.5 ~ < 14.0)
    // 5등: 10.0% (14.0 ~ < 24.0)
    // 6등: 20.0% (24.0 ~ < 44.0)
    // 7등: 56.0% (44.0 ~ 100.0)
    final randVal = Random().nextDouble() * 100.0;
    final LotteryPrize prize;
    if (randVal < 0.5) {
      prize = LotteryPrize.prizes[0];
    } else if (randVal < 2.5) {
      prize = LotteryPrize.prizes[1];
    } else if (randVal < 6.5) {
      prize = LotteryPrize.prizes[2];
    } else if (randVal < 14.0) {
      prize = LotteryPrize.prizes[3];
    } else if (randVal < 24.0) {
      prize = LotteryPrize.prizes[4];
    } else if (randVal < 44.0) {
      prize = LotteryPrize.prizes[5];
    } else {
      prize = LotteryPrize.prizes[6];
    }

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ticketsRef);
      final current = (snap.data()?['count'] as num?)?.toInt() ?? 0;
      if (current <= 0) {
        throw Exception('뽑기권이 부족합니다');
      }
      transaction.set(ticketsRef, {
        'count': current - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final newInventoryDoc = inventoryRef.doc();
      transaction.set(newInventoryDoc, {
        'rank': prize.rank,
        'reward': prize.reward,
        'emoji': prize.emoji,
        'wonAt': FieldValue.serverTimestamp(),
        'isUsed': false,
      });
    });

    return prize;
  }

  Stream<List<LotteryInventoryItem>> watchInventory(String familyCode) {
    return _inventoryCol(familyCode)
        .orderBy('wonAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => LotteryInventoryItem.fromFirestore(doc)).toList());
  }

  Future<void> useItem(String familyCode, String itemId) async {
    // Delete item when used as requested by user
    await _inventoryCol(familyCode).doc(itemId).delete();
  }
}
