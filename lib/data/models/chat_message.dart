import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderRole; // child | dad | mom
  final String senderName; // 채이현, 아빠, 엄마
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderRole: d['senderRole'] as String? ?? 'child',
      senderName: d['senderName'] as String? ?? '가족',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderRole': senderRole,
    'senderName': senderName,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
