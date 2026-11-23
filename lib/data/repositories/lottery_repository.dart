import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lottery_item.dart';

class LotteryRepository {
  final FirebaseFirestore _firestore;

  LotteryRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _ticketsDoc(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('lottery_data').doc('tickets');

  CollectionReference<Map<String, dynamic>> _inventoryCol(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('lottery_inventory');

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 4));
    }
  }

  Stream<int> watchTickets(String familyCode) {
    if (familyCode.trim().isEmpty) return Stream.value(0);
    return _ticketsDoc(familyCode.trim()).snapshots().map((snap) {
      if (!snap.exists) return 0;
      final data = snap.data();
      return (data?['count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> addTickets(String familyCode, int count) async {
    final code = familyCode.trim();
    if (code.isEmpty) throw Exception('가족 코드가 비어 있습니다.');
    await _ensureAuth();
    await _ticketsDoc(code).set({
      'count': FieldValue.increment(count),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<LotteryPrize> draw(String familyCode) async {
    final code = familyCode.trim();
    if (code.isEmpty) throw Exception('가족 코드가 비어 있습니다.');
    await _ensureAuth();

    final ticketsRef = _ticketsDoc(code);
    final inventoryRef = _inventoryCol(code);

    // Pick prize based on probability distribution:
    // 1등: 0.5% (0.0 ~ < 0.5)
    // 2등: 2.5% (0.5 ~ < 3.0)
    // 3등: 5.0% (3.0 ~ < 8.0)
    // 4등: 12.0% (8.0 ~ < 20.0)
    // 5등: 15.0% (20.0 ~ < 35.0)
    // 6등: 25.0% (35.0 ~ < 60.0)
    // 7등: 40.0% (60.0 ~ 100.0)
    final randVal = Random().nextDouble() * 100.0;
    final LotteryPrize prize;
    if (randVal < 0.5) {
      prize = LotteryPrize.prizes[0];
    } else if (randVal < 3.0) {
      prize = LotteryPrize.prizes[1];
    } else if (randVal < 8.0) {
      prize = LotteryPrize.prizes[2];
    } else if (randVal < 20.0) {
      prize = LotteryPrize.prizes[3];
    } else if (randVal < 35.0) {
      prize = LotteryPrize.prizes[4];
    } else if (randVal < 60.0) {
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
    final code = familyCode.trim();
    if (code.isEmpty) return Stream.value([]);
    return _inventoryCol(code)
        .orderBy('wonAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((doc) => LotteryInventoryItem.fromFirestore(doc))
            .where((item) => !item.isUsed)
            .toList());
  }

  Future<void> useItem(String familyCode, String itemId) async {
    final code = familyCode.trim();
    if (code.isEmpty || itemId.isEmpty) return;
    await _ensureAuth();
    final docRef = _inventoryCol(code).doc(itemId);
    // Mark as used first so listeners filter it out immediately, then delete document
    try {
      await docRef.update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    try {
      await docRef.delete();
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
    }
  }
}
