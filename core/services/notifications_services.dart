import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:doobidoobab/core/utils/logger.dart';

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 알림 설정값
  bool _reminderEnabled = true;
  int _reminderDelaySeconds = 5; // 백그라운드 진입 후 알림까지의 딜레이 (초)
  Timer? _reminderTimer;

  // 사용자가 오늘의 학습을 완료했는지 여부
  bool _isDailyStudyCompleted = false;

  /// 서비스 초기화
  Future<void> init() async {
    // 알림 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Flutter 기본 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    AppLogger.info('알림 서비스 초기화 완료');
  }

  /// 앱 생명주기 상태 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 갈 때
        _onAppHide();
        break;
      case AppLifecycleState.resumed:
        // 앱이 다시 포그라운드로 돌아올 때
        _onAppResume();
        break;
      case AppLifecycleState.inactive:
        // 앱이 일시적으로 비활성화될 때 (예: 전화 수신)
        break;
      case AppLifecycleState.detached:
        // 앱이 완전히 종료될 때
        break;
      default:
        break;
    }
  }

  /// 서비스 정리
  void dispose() {
    // 앱 생명주기 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    // 타이머 취소
    _cancelReminderTimer();
  }

  /// 앱이 백그라운드로 갈 때 호출
  void _onAppHide() {
    if (!_reminderEnabled || _isDailyStudyCompleted) return;

    AppLogger.info('앱이 백그라운드로 이동, 학습 알림 예약');

    // 기존 타이머 취소
    _cancelReminderTimer();

    // 새 타이머 생성
    _reminderTimer = Timer(Duration(seconds: _reminderDelaySeconds), () {
      _showStudyReminder();
    });
  }

  /// 앱이 다시 포그라운드로 돌아올 때 호출
  void _onAppResume() {
    // 알림 타이머 취소
    _cancelReminderTimer();
    AppLogger.info('앱이 포그라운드로 복귀, 알림 타이머 취소');
  }

  /// 알림 타이머 취소
  void _cancelReminderTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// 학습 알림 표시
  Future<void> _showStudyReminder() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_study_reminder',
      '오늘의 학습 알림',
      channelDescription: '오늘의 학습을 완료하지 않았을 때 알림을 보냅니다.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '오늘의 학습을 완료해주세요!',
      color: Color(0xFFFF8A65), // 알림 색상 (테마에 맞게 조정)
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      '📚 오늘의 학습이 기다리고 있어요!', // 제목
      '잠시만 시간을 내어 단어 학습을 완료해보세요! 🌟 꾸준한 학습이 실력 향상의 비결입니다!', // 내용
      details,
    );

    AppLogger.info('학습 알림 표시됨');
  }

  /// 알림을 탭했을 때 호출되는 함수
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // 앱 내 필요한 화면으로 이동하는 로직
    // 예: 네비게이터를 통해 학습 화면으로 이동
    AppLogger.info('알림 응답: ${response.payload}');
  }

  /// 오늘의 학습 완료 상태 설정
  void setDailyStudyCompleted(bool isCompleted) {
    _isDailyStudyCompleted = isCompleted;
    AppLogger.info('오늘의 학습 완료 상태 변경: $isCompleted');
  }

  /// 알림 활성화 여부 설정
  void setReminderEnabled(bool enabled) {
    _reminderEnabled = enabled;
  }

  /// 알림 딜레이 시간 설정 (초)
  void setReminderDelay(int seconds) {
    _reminderDelaySeconds = seconds;
  }
}
