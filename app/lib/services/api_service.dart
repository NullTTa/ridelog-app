import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/category.dart';
import '../models/maintenance_record.dart';
import '../models/summary.dart';
import 'record_repository.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Spring Boot 서버(/api)와 통신하는 클래스 (서버 모드)
class ApiService implements RecordRepository {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 8);
  static const _jsonHeader = {'Content-Type': 'application/json; charset=utf-8'};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConfig.baseUrl}/api$path').replace(queryParameters: query);

  @override
  bool get isDemo => false;

  /// 서버 접속 확인: /api/summary 가 제한 시간 안에 2xx 로 응답하면 true
  Future<bool> ping({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final res = await _client.get(_uri('/summary')).timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<MaintenanceRecord>> fetchRecords({Category? category}) async {
    final res = await _send(() => _client.get(
          _uri('/records', category == null ? null : {'category': category.code}),
        ));
    final list = _decode(res) as List;
    return list.map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<MaintenanceRecord> fetchRecord(int id) async {
    final res = await _send(() => _client.get(_uri('/records/$id')));
    return MaintenanceRecord.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<MaintenanceRecord> createRecord(MaintenanceRecord record) async {
    final res = await _send(() => _client.post(
          _uri('/records'),
          headers: _jsonHeader,
          body: jsonEncode(record.toJson()),
        ));
    return MaintenanceRecord.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<MaintenanceRecord> updateRecord(int id, MaintenanceRecord record) async {
    final res = await _send(() => _client.put(
          _uri('/records/$id'),
          headers: _jsonHeader,
          body: jsonEncode(record.toJson()),
        ));
    return MaintenanceRecord.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecord(int id) async {
    final res = await _send(() => _client.delete(_uri('/records/$id')));
    _decode(res);
  }

  @override
  Future<Summary> fetchSummary() async {
    final res = await _send(() => _client.get(_uri('/summary')));
    return Summary.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final res = await _send(() => _client.get(_uri('/categories')));
    final list = _decode(res) as List;
    return list.map((e) => Category.fromCode((e as Map<String, dynamic>)['code'] as String)).toList();
  }

  // ---- 공통 처리 ----

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } catch (_) {
      throw ApiException('서버에 연결할 수 없습니다.\n(${AppConfig.baseUrl}) 서버가 켜져 있는지 확인해 주세요.');
    }
  }

  dynamic _decode(http.Response res) {
    // 한글 깨짐 방지: bodyBytes 를 UTF-8로 직접 디코딩
    final text = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    String msg = '요청 실패 (${res.statusCode})';
    try {
      final body = jsonDecode(text);
      if (body is Map && body['message'] != null) msg = body['message'].toString();
    } catch (_) {}
    throw ApiException(msg);
  }
}
