import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../core/constants/app_constants.dart';
import '../services/hive_service.dart';

/// Keyed by songId -> last-played epoch millis.
class HistoryRepository {
  Box<int> get _box => HiveService.historyBox;

  List<String> recentSongIdsDescending({int? limit}) {
    final entries = _box.toMap().entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final ids = entries.map((e) => e.key as String).toList();
    if (limit != null && ids.length > limit) return ids.sublist(0, limit);
    return ids;
  }

  Future<void> recordPlay(String songId) async {
    await _box.put(songId, DateTime.now().millisecondsSinceEpoch);
    await _trim();
  }

  Future<void> clear() => _box.clear();

  Future<void> _trim() async {
    if (_box.length <= AppConstants.maxHistoryEntries) return;
    final entries = _box.toMap().entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final overflow = entries.length - AppConstants.maxHistoryEntries;
    final toRemove = entries.take(overflow).map((e) => e.key);
    await _box.deleteAll(toRemove);
  }
}
