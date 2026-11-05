import 'package:intl/intl.dart';

final _won = NumberFormat('#,###');
final _date = DateFormat('yyyy.MM.dd');

String formatWon(int value) => '${_won.format(value)}원';
String formatKm(int value) => '${_won.format(value)}km';
String formatDate(DateTime d) => _date.format(d);
