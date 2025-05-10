import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 메시지 모델 클래스
class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  // JSON 직렬화/역직렬화
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isMe: json['isMe'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// 채팅 상태 클래스
class ChatState {
  final List<Message> messages;
  final bool showAttachmentOptions;

  ChatState({
    required this.messages,
    this.showAttachmentOptions = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? showAttachmentOptions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      showAttachmentOptions:
          showAttachmentOptions ?? this.showAttachmentOptions,
    );
  }
}

// 채팅 상태 관리 StateNotifier
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: [])) {
    _loadMessages();
  }

  // 메시지 로드
  Future<void> _loadMessages() async {
    // 기본 예시 메시지 생성
    List<Message> initialMessages = [
      Message(
        text: "안녕하세요! 무엇을 도와드릴까요?",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Message(
        text: "오늘 출근 기록을 확인하고 싶어요.",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        text: "네, 오늘 출근 기록이 9시 30분에 확인되었습니다.",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      Message(
        text: "혹시 근무 시간 계산도 해줄 수 있나요?",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      Message(
        text: "네, 현재까지 총 근무 시간은 4시간 15분입니다. (점심시간 제외)",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    // 필요하다면 저장된 메시지 로드 (SharedPreferences 사용)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getString('chat_messages');

      if (savedMessages != null) {
        final List<dynamic> decoded = jsonDecode(savedMessages);
        final List<Message> messages =
            decoded.map((item) => Message.fromJson(item)).toList();

        // 저장된 메시지가 있으면 그것을 사용, 없으면 초기 메시지 사용
        state = ChatState(
            messages: messages.isNotEmpty ? messages : initialMessages);
        return;
      }
    } catch (e) {
      print('메시지 로드 오류: $e');
    }

    // 저장된 메시지가 없거나 오류 발생시 초기 메시지 사용
    state = ChatState(messages: initialMessages);
  }

  // 메시지 저장
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedMessages = jsonEncode(
        state.messages.map((m) => m.toJson()).toList(),
      );
      await prefs.setString('chat_messages', encodedMessages);
    } catch (e) {
      print('메시지 저장 오류: $e');
    }
  }

  // 메시지 보내기
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessages = [
      ...state.messages,
      Message(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    ];

    state = state.copyWith(messages: newMessages);
    _saveMessages();
  }

  // 봇 메시지 추가 (챗봇 응답 시뮬레이션)
  void addBotMessage(String text) {
    final newMessages = [
      ...state.messages,
      Message(
        text: text,
        isMe: false,
        timestamp: DateTime.now(),
      ),
    ];

    state = state.copyWith(messages: newMessages);
    _saveMessages();
  }

  // 빠른 반응 전송 (예: 👍)
  void sendReaction(String reaction) {
    sendMessage(reaction);
  }

  // 첨부 옵션 표시/숨김 토글
  void toggleAttachmentOptions() {
    state = state.copyWith(showAttachmentOptions: !state.showAttachmentOptions);
  }
}

// 채팅 Provider 정의
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
