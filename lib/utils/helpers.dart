import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/registration.dart';
import 'package:intl/intl.dart' as intl;

class Helpers {
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date).inSeconds;
    if (diff < 60) return 'الآن';
    if (diff < 3600) return 'منذ ${(diff / 60).floor()} دقيقة';
    if (diff < 86400) return 'منذ ${(diff / 3600).floor()} ساعة';
    if (diff < 604800) return 'منذ ${(diff / 86400).floor()} يوم';
    return 'منذ ${(diff / 604800).floor()} أسبوع';
  }

  static String formatDate(DateTime date) {
    final formatter = intl.DateFormat('yyyy/MM/dd', 'ar');
    return formatter.format(date);
  }

  static String formatTime(DateTime date) {
    final formatter = intl.DateFormat('HH:mm', 'ar');
    return formatter.format(date);
  }

  static Future<void> copyToClipboard(Registration r) async {
    final text =
        'Email: ${r.email}\nPassword: ${r.password}\nIP: ${r.ipAddress ?? 'N/A'}\nDate: ${r.createdAt.toLocal()}';
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> exportCSV(List<Registration> data) async {
    String csv = '#,Email,Password,IP,Date\n';
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      csv +=
          '${i + 1},"${r.email}","${r.password}","${r.ipAddress ?? ''}","${r.createdAt.toLocal()}"\n';
    }
    await _shareFile(csv, 'data.csv');
  }

  static Future<void> exportJSON(List<Registration> data) async {
    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(data.map((r) => r.toJson()).toList());
    await _shareFile(jsonStr, 'data.json');
  }

  static Future<void> _shareFile(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: filename);
  }

  static final List<String> dayNames = [
    'أحد',
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت'
  ];
}