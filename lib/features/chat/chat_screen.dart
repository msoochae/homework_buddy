import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../data/models/chat_message.dart';
import '../../services/local_prefs_service.dart';
import '../../services/notification_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  DateTime _initialLoadTime = DateTime.now();
  final Set<String> _notifiedIds = {};

  @override
  void initState() {
    super.initState();
    _initialLoadTime = DateTime.now();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getSenderName(String role) {
    switch (role) {
      case 'child':
        return '채이현';
      case 'dad':
        return '아빠';
      case 'mom':
        return '엄마';
      default:
        return '가족';
    }
  }

  String _getSenderEmoji(String role) {
    switch (role) {
      case 'child':
        return '👧';
      case 'dad':
        return '👨';
      case 'mom':
        return '👩';
      default:
        return '👤';
    }
  }

  Future<void> _sendMessage(String familyCode) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final myRole = LocalPrefsService.role?.name ?? 'child';
    final myName = _getSenderName(myRole);

    final msg = ChatMessage(
      id: '',
      senderRole: myRole,
      senderName: myName,
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(chatRepositoryProvider).sendMessage(familyCode, msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  void _checkNewMessageNotification(List<ChatMessage> messages) {
    final myRole = LocalPrefsService.role?.name ?? 'child';
    for (final msg in messages) {
      if (msg.senderRole != myRole &&
          msg.createdAt.isAfter(_initialLoadTime.subtract(const Duration(seconds: 2))) &&
          !_notifiedIds.contains(msg.id) &&
          msg.id.isNotEmpty) {
        _notifiedIds.add(msg.id);
        NotificationService.showNow(
          id: msg.createdAt.millisecondsSinceEpoch % 100000,
          title: '[가족 채팅] ${msg.senderName}',
          body: msg.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyCode = ref.watch(familyCodeProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final myRole = LocalPrefsService.role?.name ?? 'child';

    messagesAsync.whenData((msgs) {
      _checkNewMessageNotification(msgs);
    });

    final timeFormat = DateFormat('a h:mm', 'ko_KR');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9), // Modern soft warm canvas
      appBar: AppBar(
        title: const Text('가족 채팅 💬'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        '아직 대화가 없어요.\n가족에게 첫 인사를 건네보세요! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest messages at bottom
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderRole == myRole;
                      final formattedTime = timeFormat.format(msg.createdAt);

                      if (isMe) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formattedTime,
                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B5FEF), // Modern Indigo
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(4),
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5B5FEF).withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: const TextStyle(fontSize: 15, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _getSenderEmoji(msg.senderRole),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(18),
                                                bottomLeft: Radius.circular(18),
                                                bottomRight: Radius.circular(18),
                                              ),
                                              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.03),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              msg.text,
                                              style: const TextStyle(fontSize: 15, color: Color(0xFF191F28)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('채팅 로딩 실패: $e')),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '가족에게 메시지 보내기...',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(familyCode),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(familyCode),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FEF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
