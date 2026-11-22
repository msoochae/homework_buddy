import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _messagesCol(String familyCode) =>
      _firestore.collection('families').doc(familyCode).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String familyCode) {
    return _messagesCol(familyCode)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String familyCode, ChatMessage msg) async {
    await _messagesCol(familyCode).add({
      'senderRole': msg.senderRole,
      'senderName': msg.senderName,
      'text': msg.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
