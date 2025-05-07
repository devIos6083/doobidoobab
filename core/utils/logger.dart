/// 애플리케이션 로깅 유틸리티
///
/// 앱 전체에서 일관된 로깅을 제공합니다.
class AppLogger {
  static bool _enableDebugLogs = true;

  /// 디버그 로그 활성화/비활성화 설정
  static set enableDebugLogs(bool value) {
    _enableDebugLogs = value;
  }

  /// 정보 메시지 로깅
  static void info(String message) {
    if (_enableDebugLogs) {
      print('ℹ️ 정보: $message');
    }
  }

  /// 디버그 메시지 로깅
  static void debug(String message) {
    if (_enableDebugLogs) {
      print('🔍 디버그: $message');
    }
  }

  /// 경고 메시지 로깅
  static void warning(String message) {
    print('⚠️ 경고: $message');
  }

  /// 오류 메시지 로깅 (선택적 예외 및 스택 트레이스 포함)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('❌ 오류: $message');
    if (error != null) {
      print('예외: $error');
      if (stackTrace != null) {
        print('스택 트레이스: $stackTrace');
      }
    }
  }

  /// 중요 이벤트 로깅 (사용자 액션, 화면 전환 등)
  static void event(String message) {
    print('📊 이벤트: $message');
  }
}
