import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

/// 기기 및 앱 정보 수집 DataSource
@lazySingleton
class DeviceInfoDataSource {
  /// 유저 기기 및 앱 버전 정보 수집
  Future<Map<String, dynamic>> collectDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    final Map<String, dynamic> deviceData = {
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
    };

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData['os'] = 'Android';
        deviceData['os_version'] = androidInfo.version.release;
        deviceData['model'] = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData['os'] = 'iOS';
        deviceData['os_version'] = iosInfo.systemVersion;
        deviceData['model'] = iosInfo.utsname.machine;
      }
    } catch (e) {
      Log.w('기기 정보 수집 실패 (무시됨): $e');
    }

    return deviceData;
  }
}
