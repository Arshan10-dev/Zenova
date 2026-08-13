import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around permission_handler. `Permission.audio` resolves to
/// READ_MEDIA_AUDIO on Android 13+ and READ_EXTERNAL_STORAGE below that,
/// matching the two `<uses-permission>` entries declared in the manifest.
class PermissionService {
  PermissionService._();

  static Future<bool> hasAudioPermission() async {
    final status = await Permission.audio.status;
    return status.isGranted;
  }

  static Future<PermissionStatus> requestAudioPermission() {
    return Permission.audio.request();
  }

  static Future<bool> isAudioPermissionPermanentlyDenied() async {
    final status = await Permission.audio.status;
    return status.isPermanentlyDenied;
  }

  static Future<void> requestNotificationPermissionIfNeeded() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<bool> openSettings() => openAppSettings();
}
