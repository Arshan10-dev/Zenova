import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

bool isSupportedAudioFile(String path) {
  final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
  return AppConstants.supportedExtensions.contains(ext);
}

String titleFromFileName(String path) {
  final name = p.basenameWithoutExtension(path);
  final spaced = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  if (spaced.isEmpty) return 'Unknown Title';
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String parentFolderPath(String filePath) => p.dirname(filePath);

String folderDisplayName(String folderPath) => p.basename(folderPath);
