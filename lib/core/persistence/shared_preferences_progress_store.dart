import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/themes/domain/app_progress_data.dart';
import 'progress_store.dart';

class SharedPreferencesProgressStore implements ProgressStore {
  SharedPreferencesProgressStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _progressKey = 'match_iq_app_progress';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppProgressData> load() async {
    final rawData = await _preferences.getString(_progressKey);
    if (rawData == null || rawData.isEmpty) {
      return const AppProgressData.initial();
    }

    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map) {
        return AppProgressData.fromJson(Map<String, Object?>.from(decoded));
      }
    } on FormatException {
      return const AppProgressData.initial();
    }

    return const AppProgressData.initial();
  }

  @override
  Future<void> save(AppProgressData data) async {
    await _preferences.setString(_progressKey, jsonEncode(data.toJson()));
  }
}
