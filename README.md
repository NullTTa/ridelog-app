# 🏍️ RideLog — 바이크 정비 기록 앱

> Flutter 모바일 앱 + Spring Boot REST API 서버 연동 프로젝트

오토바이 정비할 때마다 "엔진오일 언제 갈았더라?", "지금까지 정비비 얼마 썼지?"가 늘 헷갈려서 만든 앱입니다.
정비 기록을 남기면 **분류별 권장 교체 주기로 다음 정비 시점을 계산**해서 홈 화면에 보여줍니다.

## 주요 기능

| 기능 | 설명 |
|---|---|
| 정비 기록 CRUD | 분류·내용·주행거리·비용·정비일·정비소·메모 등록 / 조회 / 수정 / 삭제 |
| 분류 필터 | 엔진오일, 타이어, 브레이크, 체인, 배터리, 기타 칩으로 목록 필터링 |
| 요약 카드 | 총 정비 횟수, 누적 비용, 최근 주행거리 |
| 다음 정비 예정 | 분류별 마지막 정비 주행거리 + 권장 주기 → 남은 km 표시 (지나면 빨간색 경고) |
| 입력 검증 | 앱(Form validator) + 서버(Bean Validation) 이중 검증, 에러 메시지 표시 |
| 예외 처리 | 서버 미연결·404·400 응답을 사용자 메시지로 변환, 새로고침/다시 시도 |

## 기술 스택

- **App** : Flutter 3, Dart 3, Material 3, `http`, `intl`
- **Server** : Java 17, Spring Boot 3.3, Spring Data JPA, Validation, Lombok
- **DB** : H2(파일 모드, 기본) / MySQL(`mysql` 프로필)

## 구조

```
ridelog/
├── app/                        # Flutter 앱
│   └── lib/
│       ├── main.dart
│       ├── config.dart         # 서버 주소 (에뮬레이터 10.0.2.2 자동 처리)
│       ├── models/             # Category, MaintenanceRecord, Summary
│       ├── services/           # ApiService (REST 통신)
│       ├── screens/            # 홈 / 상세 / 등록·수정
│       ├── widgets/            # 요약 카드, 목록 타일
│       └── utils/format.dart   # 원·km·날짜 포맷
└── server/                     # Spring Boot 서버
    └── src/main/java/com/ridelog/server/
        ├── record/             # Entity, Repository, Service, Controller, DTO
        └── common/             # CORS 설정, 전역 예외 처리
```

## REST API

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/records?category=ENGINE_OIL` | 목록 (category 생략 시 전체) |
| GET | `/api/records/{id}` | 상세 |
| POST | `/api/records` | 등록 |
| PUT | `/api/records/{id}` | 수정 |
| DELETE | `/api/records/{id}` | 삭제 |
| GET | `/api/summary` | 요약 + 다음 정비 예정 |
| GET | `/api/categories` | 분류 목록 |

요청 예시
```json
{
  "category": "ENGINE_OIL",
  "title": "엔진오일 교체",
  "mileage": 12000,
  "cost": 35000,
  "serviceDate": "2026-11-01",
  "shop": "부평 바이크",
  "memo": "10W-30"
}
```

## 실행 방법

### 준비물
- JDK 17 이상 (JDK 25에서도 빌드·실행 확인)
- Maven 3.9 이상 (저장소에 Maven Wrapper `mvnw`가 없으므로 별도 설치 필요)
- Flutter 3.x (Flutter 3.47.9 / Dart 3.13에서 `flutter analyze`·`flutter test` 확인)

### 1) 서버
IntelliJ / STS에서 `server` 폴더를 Maven 프로젝트로 열고 `RidelogServerApplication` 실행
(또는 터미널에서 아래처럼 실행 — Windows PowerShell 5.1은 `&&`를 지원하지 않으므로 두 줄로 입력)

```bash
cd server
mvn spring-boot:run
```

- 실행 후 `http://localhost:8080/api/summary` 에 접속해 JSON이 오면 정상입니다.

- 기본은 H2 파일 DB라 DB 설치 없이 바로 실행됩니다. → `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:file:./data/ridelog`)
- MySQL 사용 시: `ridelog` 스키마 생성 후 `application.yml`의 계정 수정 → `mysql` 프로필로 실행

### 2) 앱
```bash
cd app
flutter create . --org com.ridelog --project-name ridelog   # 안드로이드/iOS 플랫폼 폴더 생성 (최초 1회)
flutter pub get
flutter run
```

- 안드로이드 에뮬레이터는 자동으로 `http://10.0.2.2:8080`, 크롬/iOS 시뮬레이터는 `localhost:8080`으로 접속합니다.
- 실제 폰으로 테스트할 때는 PC의 내부 IP를 지정하세요.
  `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080`

## 테스트
- 서버: `mvn test` (MockMvc로 등록 → 목록 → 요약 → 검증 실패 → 삭제 → 404 흐름 검증)
- 앱: `flutter test` (JSON ↔ 모델 변환)
