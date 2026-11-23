import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _messagesCol(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String familyCode) {
    if (familyCode.trim().isEmpty) return Stream.value([]);
    return _messagesCol(familyCode)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String familyCode, ChatMessage msg) async {
    final code = familyCode.trim();
    if (code.isEmpty) {
      throw Exception('가족 코드가 비어 있습니다.');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 4));
    }
    await _messagesCol(code).add({
      'senderRole': msg.senderRole,
      'senderName': msg.senderName,
      'text': msg.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
