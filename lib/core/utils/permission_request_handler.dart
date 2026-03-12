import 'dart:io';
import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/storage/local_storage.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestHandler {
  static bool _tokenRefreshListenerInitialized = false;

  static Future<void> requestOptionalPermissionsSequentially() async {
    await _requestLocationPermission();
    await requestNotificationPermission();
  }

  /// `FCM token`이 갱신될 때마다 Supabase의 `users.fcm_token`을 업데이트합니다.
  /// - 로그아웃 상태에서는 userId가 없으므로 DB 업데이트를 하지 않습니다.
  /// - 앱을 켤 때마다 무지성 저장하지 않도록, 이전에 동기화한 토큰과 비교합니다.
  static Future<void> initFcmTokenRefreshListener() async {
    if (_tokenRefreshListenerInitialized) return;
    _tokenRefreshListenerInitialized = true;

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        await syncFcmTokenToSupabase(newToken: newToken);
      },
      onError: (err) {
        // 리스너 자체 실패는 앱 흐름을 막지 않습니다.
        print('FCM token refresh listener error: $err');
      },
    );
  }

  /// 알림 권한 요청 (수정됨)
  static Future<PermissionStatus> requestNotificationPermission() async {
    if (!await _shouldRequestNotificationPermission()) {
      return PermissionStatus.granted;
    }

    final currentStatus = await Permission.notification.status;

    // 1. 이미 권한이 있다면 토큰을 동기화(캐시 비교 후 필요할 때만 DB 업데이트)
    if (currentStatus.isGranted || currentStatus.isLimited) {
      await syncFcmTokenToSupabase();
      return currentStatus;
    }

    // 2. 권한 요청
    final newStatus = await Permission.notification.request();

    // 3. 사용자가 방금 허용했다면 토큰 발급
    if (newStatus.isGranted || newStatus.isLimited) {
      await syncFcmTokenToSupabase();
    }

    return newStatus;
  }

  /// 현재(또는 주어진) FCM 토큰을 Supabase에 동기화합니다.
  ///
  /// 재로그인 엣지 케이스 대응:
  /// - 앱 재로그인 시 `onTokenRefresh`가 발생하지 않을 수 있어,
  ///   로그인 성공 시점에 이 함수를 한 번 호출해 줍니다.
  ///
  /// - 로그인된 사용자(userId)가 있어야만 DB 업데이트를 합니다.
  /// - 로컬에 저장된 마지막 동기화 토큰과 같으면 DB 업데이트를 스킵합니다.
  static Future<void> syncFcmTokenToSupabase({String? newToken}) async {
    try {
      final token = newToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final client = SupabaseUtils.getClientOrNull();
      final userId = client?.auth.currentUser?.id;

      // 로그아웃 상태라면 DB 업데이트/캐시 업데이트를 하지 않습니다.
      if (client == null || userId == null) return;

      final localStorage = getIt<LocalStorage>();
      final lastSyncedToken = await localStorage.getEncrypted(AuthConstants.fcmTokenKey);
      if (lastSyncedToken != null && lastSyncedToken == token) return;

      print("FCM token sync: $token");
      await client.from('users').update({
        'fcm_token': token,
      }).eq('id', userId);

      // 성공했을 때만 캐시 갱신 -> 실패 시 중복 업데이트 가능(재시도)하지만 안전합니다.
      await localStorage.saveEncrypted(AuthConstants.fcmTokenKey, token);
    } catch (e) {
      print("FCM token sync 실패: $e");
    }
  }

  /// 위치 권한 요청
  static Future<void> _requestLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  /// 현재 권한 상태를 가져오는 메서드
  static Future<PermissionStatusBundle> getCurrentPermissionStatus() async {
    final location = await Permission.location.isGranted;
    final notification = await isNotificationPermissionGranted();

    return PermissionStatusBundle(
      location: location,
      notification: notification,
    );
  }

  /// 권한이 모두 허용되었는지 확인하는 메서드
  static Future<bool> areAllPermissionsGranted() async {
    final status = await getCurrentPermissionStatus();
    return status.location && status.notification;
  }

  /// 알림 권한이 허용되었는지 확인하는 메서드
  static Future<bool> isNotificationPermissionGranted() async {
    if (!await _shouldRequestNotificationPermission()) {
      return true;
    }
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  /// 모든 권한 상태 변경 감지
  static Future<PermissionStatusBundle> checkAllPermissionChanges(
    PermissionStatusBundle currentStatus,
  ) async {
    final newLocation = await Permission.location.isGranted;
    final newNotification = await isNotificationPermissionGranted();

    return PermissionStatusBundle(
      location: newLocation,
      notification: newNotification,
    );
  }

  static Future<bool> _shouldRequestNotificationPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }

    return false;
  }
}

class PermissionStatusBundle {
  final bool location;
  final bool notification;

  PermissionStatusBundle({
    required this.location,
    required this.notification,
  });
}
