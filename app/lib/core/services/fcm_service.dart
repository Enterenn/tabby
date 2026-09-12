import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Gère Firebase Cloud Messaging : permissions, token, messages.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Initialise les permissions et le token. Appelé après authentification.
  Future<void> init() async {
    // Demande la permission (Android 13+)
    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Enregistre le token initial
    await _refreshToken();

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fm.onTokenRefresh.listen(_sendTokenToBackend);

    // Optionnel : affiche les notifs en foreground sur Android
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  /// Supprime le token côté backend (appelé au logout).
  Future<void> deleteToken() async {
    await dispose();
    try {
      final token = await _fm.getToken();
      if (token != null) {
        await apiClient.dio.delete('/devices/token', data: {'token': token});
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
      await apiClient.dio.post('/devices/token', data: {
        'token': token,
        'platform': 'android',
      });
      debugPrint('[FCM] Token enregistré');
    } catch (e) {
      debugPrint('[FCM] _sendTokenToBackend error: $e');
    }
  }
}

/// Handler exécuté en background (isolat séparé — doit être top-level).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Pas besoin de faire quoi que ce soit ici :
  // Android affiche la notification automatiquement.
  debugPrint('[FCM BG] ${message.notification?.title}');
}
