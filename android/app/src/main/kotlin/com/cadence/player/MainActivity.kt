package com.Zenova.player

import com.ryanheise.audioservice.AudioServiceActivity

/**
 * Zenova's single native entry point.
 *
 * Extending [AudioServiceActivity] (rather than plain FlutterActivity) is what lets
 * audio_service bind Zenova's background playback service to this activity's
 * Flutter engine, which is what powers the notification, lock-screen, and
 * Bluetooth/headset media controls. If you ever need custom platform channels,
 * add them here inside an overridden configureFlutterEngine().
 */
class MainActivity : AudioServiceActivity()
