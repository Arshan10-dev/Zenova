import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/audio_handler.dart';
import 'services/hive_service.dart';
import 'services/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge, transparent system bars — Cadence draws its own
  // backgrounds behind the status/nav bar areas on every screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await HiveService.init();

  final audioHandler = await AudioService.init(
    builder: () => CadenceAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.cadence.player.audio',
      androidNotificationChannelName: 'Cadence Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      preloadArtwork: false,
    ),
  );

  // Best-effort — a denied notification permission degrades to a silent
  // foreground service rather than blocking playback.
  unawaited(PermissionService.requestNotificationPermissionIfNeeded());

  runApp(CadenceApp(audioHandler: audioHandler));
}
