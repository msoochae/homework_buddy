import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';

class HomeworkRepository {
  final FirebaseFirestore _db;
  final String familyCode;

  HomeworkRepository({required this.familyCode, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('families').doc(familyCode).collection('homeworks');

  Stream<List<Homework>> watchByDate(String date) =>
      _col.where('date', isEqualTo: date).snapshots().map(
            (snap) => snap.docs.map(Homework.fromFirestore).toList(),
          );

  Stream<List<Homework>> watchActiveAndToday(String today) =>
      _col.snapshots().map((snap) {
        final list = snap.docs.map(Homework.fromFirestore).toList();
        return list.where((h) =>
          h.status == 'registered' ||
          h.status == 'in_progress' ||
          h.date == today
        ).toList();
      });

  Stream<List<Homework>> watchAll() =>
      _col.snapshots().map((snap) => snap.docs.map(Homework.fromFirestore).toList());

  Stream<List<Homework>> watchRange(String from, String to) =>
      _col
          .where('date', isGreaterThanOrEqualTo: from)
          .where('date', isLessThanOrEqualTo: to)
          .orderBy('date')
          .snapshots()
          .map((snap) => snap.docs.map(Homework.fromFirestore).toList());

  Future<void> add(Homework hw) => _col.doc(hw.id).set(hw.toFirestore());

  Future<void> update(Homework hw) => _col.doc(hw.id).update({
    'title': hw.title,
    'dueDate': hw.dueDate,
    'status': hw.status,
    'progress': hw.progress,
    'updatedAt': Timestamp.fromDate(hw.updatedAt),
    'completedAt': hw.completedAt != null ? Timestamp.fromDate(hw.completedAt!) : null,
    'dueDateOverridden': hw.dueDateOverridden,
    'startTime': hw.startTime,
    'endTime': hw.endTime,
  });

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<List<Homework>> getByDate(String date) async {
    final snap = await _col.where('date', isEqualTo: date).get();
    return snap.docs.map(Homework.fromFirestore).toList();
  }
}
