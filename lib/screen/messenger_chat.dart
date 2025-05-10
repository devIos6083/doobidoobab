// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for messages
final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<Message>>((ref) {
  return MessagesNotifier();
});

// StateNotifier for managing messages
class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier()
      : super([
          Message(
              text: "안녕하세요! 무엇을 도와드릴까요?",
              isMe: false,
              timestamp: DateTime.now().subtract(const Duration(minutes: 6))),
          Message(
              text: "오늘 출근 기록을 확인하고 싶어요.",
              isMe: true,
              timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
          Message(
              text: "네, 오늘 출근 기록이 9시 30분에 확인되었습니다.",
              isMe: false,
              timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
          Message(
              text: "혹시 근무 시간 계산도 해줄 수 있나요?",
              isMe: true,
              timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
          Message(
              text: "네, 현재까지 총 근무 시간은 4시간 15분입니다. (점심시간 제외)",
              isMe: false,
              timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
          Message(
              text: "오후 6시까지 근무하면 총 몇 시간인가요?",
              isMe: true,
              timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
          Message(
              text: "예상 근무 시간은 8시간 30분입니다. 연장 근무 여부도 확인할까요?",
              isMe: false,
              timestamp: DateTime.now())
        ]);

  void addMessage(String text, bool isMe) {
    state = [
      ...state,
      Message(
        text: text,
        isMe: isMe,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

// Provider for attachment options visibility
final attachmentVisibilityProvider = StateProvider<bool>((ref) => false);

class MessengerChatScreenRiverpod extends ConsumerWidget {
  const MessengerChatScreenRiverpod({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the messages provider
    final messages = ref.watch(messagesProvider);
    // Watch the attachment visibility provider
    final showAttachmentOptions = ref.watch(attachmentVisibilityProvider);
    // Create a TextEditingController for the message input
    final TextEditingController messageController = TextEditingController();

    // Function to send a message
    void sendMessage() {
      if (messageController.text.trim().isNotEmpty) {
        // Add the user's message
        ref.read(messagesProvider.notifier).addMessage(
              messageController.text,
              true,
            );
        messageController.clear();

        // Simulate a bot response
        Future.delayed(const Duration(seconds: 1), () {
          ref.read(messagesProvider.notifier).addMessage(
                "네, 근무 시간은 현재 5시간 30분입니다.",
                false,
              );
        });
      }
    }

    // Function to toggle attachment options
    void toggleAttachmentOptions() {
      ref.read(attachmentVisibilityProvider.notifier).state =
          !showAttachmentOptions;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70), // 🔹 앱바 높이 조정
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // 🔹 앱바 배경색
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ), // 🔹 하단을 둥글게
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 7), // 🔹 살짝 떠 있는 느낌의 그림자
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey[200], // 🔹 테두리 효과
                radius: 20,
                child: ClipOval(
                  child: Image.asset(
                    'img/chat_bot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '챗봇 상담',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI 상담 도우미', // 🔹 서브 타이틀 추가
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 영역
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final previousMessage = index < messages.length - 1
                    ? messages[messages.length - index - 2]
                    : null;

                return _buildMessageBubble(message, previousMessage);
              },
            ),
          ),

          // 첨부 옵션 영역
          if (showAttachmentOptions)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                      Icons.camera_alt, "카메라", Colors.purple),
                  _buildAttachmentOption(
                      Icons.photo_library, "앨범", Colors.green),
                  _buildAttachmentOption(Icons.mic, "마이크", Colors.orange),
                ],
              ),
            ),

          // 메시지 입력 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    showAttachmentOptions ? Icons.close : Icons.chevron_right,
                    color: Colors.blue,
                  ),
                  onPressed: toggleAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      hintStyle: GoogleFonts.sora(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Colors.blueAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.blue),
                  onPressed: () {
                    ref.read(messagesProvider.notifier).addMessage("👍", true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, Message? previousMessage) {
    bool isDifferentSender =
        previousMessage == null || previousMessage.isMe != message.isMe;

    return Column(
      crossAxisAlignment:
          message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // 🔹 다른 사람이 보낸 메시지라면 더 큰 간격 추가
        if (isDifferentSender)
          const SizedBox(height: 16)
        else
          const SizedBox(height: 10),

        Row(
          mainAxisAlignment:
              message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 🔹 챗봇 메시지인 경우 (왼쪽에 챗봇 이미지 추가)
            if (!message.isMe) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200], // 🔹 테두리 효과
                child: ClipOval(
                  child: Image.asset(
                    'img/chat_bot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 🔹 메시지 말풍선
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isMe ? Colors.blue[400] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: message.isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: message.isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    color: message.isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),

            // 🔹 사용자 메시지 오른쪽 여백 추가
            if (message.isMe) const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}
