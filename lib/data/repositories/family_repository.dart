import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyRepository {
  final FirebaseFirestore _db;

  FamilyRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<Set<String>> getHolidays(String familyCode) async {
    try {
      final doc = await _db
          .collection('families').doc(familyCode)
          .collection('settings').doc('holidays')
          .get();
      if (doc.exists) {
        return Set<String>.from(doc.data()?['dates'] ?? []);
      }
    } catch (_) {}
    return {};
  }

  Future<void> addHoliday(String familyCode, String date) async {
    await _db
        .collection('families').doc(familyCode)
        .collection('settings').doc('holidays')
        .set({'dates': FieldValue.arrayUnion([date])}, SetOptions(merge: true));
  }

  Future<void> saveDevice(String familyCode, String deviceId, String role, String fcmToken) async {
    await _db
        .collection('families').doc(familyCode)
        .collection('devices').doc(deviceId)
        .set({
      'role': role,
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String generateFamilyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
