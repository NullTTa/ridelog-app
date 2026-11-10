import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/record_repository.dart';

void main() {
  runApp(const RideLogApp());
}

class RideLogApp extends StatelessWidget {
  const RideLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8590C)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _Bootstrap(),
    );
  }
}

/// 앱 시작 시 서버(/api/summary) 접속을 3초간 확인해 서버 모드 / 로컬 데모 모드를 결정
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<RecordRepository> _ready = Repositories.resolve();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecordRepository>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('서버 연결 확인 중...'),
                ],
              ),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}
