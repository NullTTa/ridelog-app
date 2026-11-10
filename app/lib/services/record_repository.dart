import '../models/category.dart';
import '../models/maintenance_record.dart';
import '../models/summary.dart';
import 'api_service.dart';
import 'local_record_repository.dart';

/// 정비 기록 저장소 공통 인터페이스
/// - [ApiService]            : Spring Boot 서버(/api) 사용 (서버 모드)
/// - [LocalRecordRepository] : 기기 내부(shared_preferences) 사용 (오프라인 데모 모드)
/// 화면 코드는 이 인터페이스만 사용하므로 어느 쪽인지 알 필요가 없다.
abstract class RecordRepository {
  /// 오프라인 데모 모드 여부 (홈 앱바 "데모 모드" 표시용)
  bool get isDemo;

  /// 목록 (category 가 null 이면 전체) — 정비일 최신순, 같으면 나중에 등록한 순
  Future<List<MaintenanceRecord>> fetchRecords({Category? category});

  Future<MaintenanceRecord> fetchRecord(int id);

  Future<MaintenanceRecord> createRecord(MaintenanceRecord record);

  Future<MaintenanceRecord> updateRecord(int id, MaintenanceRecord record);

  Future<void> deleteRecord(int id);

  /// 총 건수·총 비용·최근 주행거리 + 분류별 다음 정비 예정
  Future<Summary> fetchSummary();

  /// 분류 목록
  Future<List<Category>> fetchCategories();
}

/// 앱 전체에서 사용하는 저장소 (앱 시작 시 [resolve] 로 결정)
class Repositories {
  Repositories._();

  static RecordRepository? _current;

  static RecordRepository get current {
    final repo = _current;
    if (repo == null) {
      throw StateError('Repositories.resolve() 가 먼저 호출되어야 합니다.');
    }
    return repo;
  }

  /// 테스트 등에서 직접 지정
  static set current(RecordRepository repo) => _current = repo;

  /// 서버(/api/summary)에 3초 안에 접속되면 서버 모드, 아니면 로컬 데모 모드
  static Future<RecordRepository> resolve({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final api = ApiService();
    final RecordRepository repo =
        await api.ping(timeout: timeout) ? api : LocalRecordRepository();
    _current = repo;
    return repo;
  }
}
