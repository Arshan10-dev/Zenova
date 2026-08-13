import 'package:flutter/foundation.dart';

import '../models/song_model.dart';
import '../repository/history_repository.dart';
import '../repository/song_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository;
  final SongRepository _songRepository;

  HistoryProvider(this._repository, this._songRepository);

  /// Reads fresh from Hive each call — cheap at these sizes and always in
  /// sync with the latest play without cross-provider coupling.
  List<SongModel> recentlyPlayed({int? limit}) {
    final ids = _repository.recentSongIdsDescending(limit: limit);
    return ids.map(_songRepository.getById).whereType<SongModel>().toList();
  }

  Future<void> clearHistory() async {
    await _repository.clear();
    notifyListeners();
  }
}
