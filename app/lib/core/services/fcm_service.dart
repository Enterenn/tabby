import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/repositories.dart';
import '../router/app_router.dart';

/// Gère Firebase Cloud Messaging : permissions, token, messages.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const _localChannel = MethodChannel('com.tabby.tabby/notifications');

  final _fm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Initialise les permissions et le token. Appelé après authentification.
  Future<void> init() async {
    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _refreshToken();

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fm.onTokenRefresh.listen(_sendTokenToBackend);

    await _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_showForeground);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;
  }

  /// Supprime le token côté backend (appelé au logout).
  Future<void> deleteToken() async {
    await dispose();
    try {
      final token = await _fm.getToken();
      if (token != null) {
        await devicesRepository.deleteToken(token);
      }
      await _fm.deleteToken();
    } catch (e) {
      debugPrint('[FCM] deleteToken error: $e');
    }
  }

  Future<void> _refreshToken() async {
    try {
      final token = await _fm.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] _refreshToken error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await devicesRepository.registerToken(token);
      debugPrint('[FCM] Token enregistré');
    } catch (e) {
      debugPrint('[FCM] _sendTokenToBackend error: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final groupId = message.data['group_id'] as String?;
    try {
      await _localChannel.invokeMethod<void>('show', {
        'title': notification.title ?? 'Tabby',
        'body': notification.body ?? '',
        'groupId': groupId,
      });
    } catch (e) {
      debugPrint('[FCM] foreground display error: $e');
      if (groupId != null && groupId.isNotEmpty) {
        navigateToGroup(groupId);
      }
    }
  }
}

/// Handler exécuté en background (isolat séparé — doit être top-level).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM BG] ${message.notification?.title}');
}
