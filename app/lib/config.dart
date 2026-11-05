import 'package:flutter/foundation.dart';

/// 서버 주소
/// - 실행 시 직접 지정: flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
/// - 지정하지 않으면
///   · 안드로이드 에뮬레이터 → 10.0.2.2 (에뮬레이터에서 본 내 PC)
///   · 웹(크롬) / iOS 시뮬레이터 / 데스크톱 → localhost
class AppConfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
