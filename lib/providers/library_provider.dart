import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/debouncer.dart';
import '../models/library_group_models.dart';
import '../models/song_model.dart';
import '../models/sort_options.dart';
import '../repository/settings_repository.dart';
import '../repository/song_repository.dart';
import '../services/file_import_service.dart';
import '../services/music_scanner_service.dart';
import '../services/permission_service.dart';

enum LibraryLoadState { idle, scanning, importing, error }

class LibraryProvider extends ChangeNotifier {
  final SongRepository _songRepository;
  final MusicScannerService _scanner;
  final FileImportService _importer;
  final SettingsRepository _settings;

  LibraryProvider(this._songRepository, this._scanner, this._importer, this._settings) {
    _sortBy = _parseSortBy(_settings.sortSongsBy);
    _sortAscending = _settings.sortSongsAscending;
    _loadFromCache();
  }

  List<SongModel> _allSongs = [];
  LibraryLoadState _state = LibraryLoadState.idle;
  String? _lastError;
  String _searchQuery = '';
  SongSortBy _sortBy = SongSortBy.title;
  bool _sortAscending = true;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  List<String> _lastSkippedImports = [];
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));

  List<SongModel> get allSongs => _allSongs;
  LibraryLoadState get state => _state;
  bool get isScanning => _state == LibraryLoadState.scanning;
  bool get isImporting => _state == LibraryLoadState.importing;
  String? get lastError => _lastError;
  bool get isEmpty => _allSongs.isEmpty;
  String get searchQuery => _searchQuery;
  SongSortBy get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  Set<String> get selectedIds => _selectedIds;
  bool get isSelectionMode => _isSelectionMode;
  List<String> get lastSkippedImports => _lastSkippedImports;

  SongModel? getById(String id) => _songRepository.getById(id);

  List<SongModel> get filteredSortedSongs {
    Iterable<SongModel> songs = _allSongs;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      songs = songs.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q));
    }
    final list = songs.toList();
    list.sort(_comparatorFor(_sortBy));
    if (!_sortAscending) return list.reversed.toList();
    return list;
  }

  List<SongModel> get recentlyAdded {
    final list = [..._allSongs]..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return list.take(AppConstants.homeSectionItemLimit).toList();
  }

  List<SongModel> get mostPlayed {
    final list = _allSongs.where((s) => s.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return list.take(AppConstants.homeSectionItemLimit).toList();
  }

  List<SongModel> get favorites {
    final list = _allSongs.where((s) => s.isFavorite).toList();
    list.sort(_comparatorFor(SongSortBy.title));
    return list;
  }

  List<AlbumInfo> get albums {
    final map = <String, List<SongModel>>{};
    for (final s in _allSongs) {
      map.putIfAbsent('${s.album}|${s.artist}', () => []).add(s);
    }
    final list = map.entries
        .map((e) => AlbumInfo(name: e.value.first.album, artist: e.value.first.artist, songs: e.value))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<ArtistInfo> get artists {
    final map = <String, List<SongModel>>{};
    for (final s in _allSongs) {
      map.putIfAbsent(s.artist, () => []).add(s);
    }
    final list = map.entries.map((e) => ArtistInfo(name: e.key, songs: e.value)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<FolderInfo> get folders {
    final map = <String, List<SongModel>>{};
    for (final s in _allSongs) {
      map.putIfAbsent(s.folderPath, () => []).add(s);
    }
    final list = map.entries
        .map((e) => FolderInfo(
              path: e.key,
              name: e.key.split('/').where((p) => p.isNotEmpty).lastOrNull ?? e.key,
              songs: e.value,
            ))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _loadFromCache() {
    _allSongs = _songRepository.getAll();
    notifyListeners();
  }

  Future<bool> scanLibrary({bool requestPermissionIfNeeded = true}) async {
    var hasPermission = await _scanner.hasPermission();
    if (!hasPermission && requestPermissionIfNeeded) {
      hasPermission = await _scanner.requestPermission();
    }
    if (!hasPermission) {
      await PermissionService.requestAudioPermission();
      hasPermission = await _scanner.hasPermission();
    }
    if (!hasPermission) return false;

    _state = LibraryLoadState.scanning;
    _lastError = null;
    notifyListeners();

    try {
      final scanned = await _scanner.scanDevice();
      await _songRepository.mergeScanResults(scanned);
      await _pruneMissingManualImports();
      _allSongs = _songRepository.getAll();
      _state = LibraryLoadState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _state = LibraryLoadState.error;
      _lastError = 'Couldn\'t scan your music library. $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _pruneMissingManualImports() async {
    final manual = _allSongs.where((s) => s.isManual).toList();
    if (manual.isEmpty) return;
    final missing = <String>[];
    for (final song in manual) {
      if (!await File(song.path).exists()) missing.add(song.id);
    }
    if (missing.isNotEmpty) await _songRepository.deleteMany(missing);
  }

  Future<void> importFiles() async {
    final paths = await _importer.pickAudioFiles();
    if (paths == null || paths.isEmpty) return;
    await _runImport(paths);
  }

  Future<void> importFolder() async {
    final folder = await _importer.pickFolder();
    if (folder == null) return;
    final paths = await _importer.collectAudioFilesInFolder(folder);
    if (paths.isEmpty) {
      _lastSkippedImports = [];
      _lastError = 'No supported audio files were found in that folder.';
      notifyListeners();
      return;
    }
    await _runImport(paths);
  }

  Future<void> _runImport(List<String> paths) async {
    _state = LibraryLoadState.importing;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _importer.importPaths(paths);
      await _songRepository.putAll(result.songs);
      _allSongs = _songRepository.getAll();
      _lastSkippedImports = result.skippedFileNames;
      _state = LibraryLoadState.idle;
      notifyListeners();
    } catch (e) {
      _state = LibraryLoadState.error;
      _lastError = 'Some songs couldn\'t be imported. $e';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String songId) async {
    await _songRepository.toggleFavorite(songId);
    _allSongs = _songRepository.getAll();
    notifyListeners();
  }

  Future<void> incrementPlayCount(String songId) async {
    await _songRepository.incrementPlayCount(songId);
    _allSongs = _songRepository.getAll();
    notifyListeners();
  }

  Future<void> removeFromLibrary(Iterable<String> songIds) async {
    await _songRepository.deleteMany(songIds);
    _allSongs = _songRepository.getAll();
    _selectedIds.removeAll(songIds);
    if (_selectedIds.isEmpty) _isSelectionMode = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchDebouncer.run(() {
      _searchQuery = query;
      notifyListeners();
    });
  }

  Future<void> setSortBy(SongSortBy sortBy) async {
    _sortBy = sortBy;
    notifyListeners();
    await _settings.setSortSongsBy(sortBy.name);
  }

  Future<void> toggleSortDirection() async {
    _sortAscending = !_sortAscending;
    notifyListeners();
    await _settings.setSortSongsAscending(_sortAscending);
  }

  void toggleSelection(String songId) {
    if (_selectedIds.contains(songId)) {
      _selectedIds.remove(songId);
    } else {
      _selectedIds.add(songId);
    }
    _isSelectionMode = _selectedIds.isNotEmpty;
    notifyListeners();
  }

  void enterSelectionMode(String initialSongId) {
    _isSelectionMode = true;
    _selectedIds.add(initialSongId);
    notifyListeners();
  }

  void selectAll(List<SongModel> songs) {
    _selectedIds
      ..clear()
      ..addAll(songs.map((s) => s.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  int Function(SongModel, SongModel) _comparatorFor(SongSortBy sortBy) {
    switch (sortBy) {
      case SongSortBy.title:
        return (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case SongSortBy.artist:
        return (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
      case SongSortBy.album:
        return (a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase());
      case SongSortBy.dateAdded:
        return (a, b) => a.dateAdded.compareTo(b.dateAdded);
      case SongSortBy.duration:
        return (a, b) => a.duration.compareTo(b.duration);
    }
  }

  SongSortBy _parseSortBy(String value) {
    return SongSortBy.values.firstWhere((e) => e.name == value, orElse: () => SongSortBy.title);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
