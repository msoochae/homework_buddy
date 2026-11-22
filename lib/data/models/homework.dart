import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/hw_date_utils.dart';

class Homework {
  final String id;
  final String date;
  final String category;
  final String title;
  final String? dueDate;
  final String status;
  final int progress;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool dueDateOverridden;
  final String? startTime; // "HH:mm"
  final String? endTime;   // "HH:mm"

  const Homework({
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    this.dueDate,
    required this.status,
    required this.progress,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueDateOverridden = false,
    this.startTime,
    this.endTime,
  });

  factory Homework.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Homework(
      id: doc.id,
      date: data['date'] as String,
      category: data['category'] as String,
      title: data['title'] as String? ?? '',
      dueDate: data['dueDate'] as String?,
      status: data['status'] as String? ?? 'registered',
      progress: (data['progress'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String? ?? 'child',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      dueDateOverridden: data['dueDateOverridden'] as bool? ?? false,
      startTime: data['startTime'] as String?,
      endTime: data['endTime'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'date': date,
    'category': category,
    'title': title,
    'dueDate': dueDate,
    'status': status,
    'progress': progress,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'dueDateOverridden': dueDateOverridden,
    'startTime': startTime,
    'endTime': endTime,
  };

  Homework copyWith({
    String? title,
    String? dueDate,
    String? status,
    int? progress,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? dueDateOverridden,
    bool clearCompletedAt = false,
    String? startTime,
    String? endTime,
    bool clearTimes = false,
  }) => Homework(
    id: id,
    date: date,
    category: category,
    title: title ?? this.title,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    dueDateOverridden: dueDateOverridden ?? this.dueDateOverridden,
    startTime: clearTimes ? null : (startTime ?? this.startTime),
    endTime: clearTimes ? null : (endTime ?? this.endTime),
  );

  int get dDay => dueDate != null ? HwDateUtils.dDay(dueDate!) : 999;

  String? get timeRangeText {
    if (startTime == null && endTime == null) return null;
    if (startTime != null && endTime != null) return '$startTime ~ $endTime';
    if (startTime != null) return '$startTime 시작';
    return '$endTime 종료';
  }
}
