import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class PlatformService {
  PlatformService();

  Future<bool> isWearOS() async {
    if (!Platform.isAndroid) return false;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final String? uiMode =
          android.systemFeatures.contains('android.hardware.type.watch')
          ? 'watch'
          : null;
      return uiMode == 'watch' ||
          (android.systemFeatures.contains('android.software.watch_faces'));
    } catch (_) {
      return false;
    }
  }

  bool get isPhoneLike {
    return !(Platform.isAndroid && false);
  }
}
