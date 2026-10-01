import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../domain/repositories/notification_repository.dart';

/// Entry point used by FCM when a message arrives while the app is in the
/// background or terminated.
///
/// Notification-type messages are rendered by the OS itself, so there is
/// nothing to do here beyond registering the handler (which also keeps data
/// messages flowing to the app when it is terminated).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Owns everything Firebase Cloud Messaging related:
///
/// * plugin / local-notification initialization,
/// * runtime notification permission (Android 13+ and iOS),
/// * device token registration under `users/{uid}/devices/{token}`,
/// * foreground presentation and background/terminated delivery,
/// * notification taps (including cold start) routed through GoRouter.
class NotificationService {
  NotificationService({
    required this._firebaseAuth,
    required this._messaging,
    required this._repository,
  });

  /// Must match the channel declared in `AndroidManifest.xml`.
  static const String defaultChannelId = 'barber_booking_default';
  static const String defaultChannelName = 'Barber Booking';
  static const String defaultChannelDescription =
      'Booking updates and appointment reminders.';

  /// Real route registered in `AppRouter` that hosts `NotificationsPage`.
  static const String notificationsRoute = '/notifications';

  /// Real booking-details route registered in `AppRouter`.
  static const String bookingDetailsRoute = '/booking-details';

  /// Booking notification types land on the booking-details page;
  /// everything else lands on the notifications list.
  static const Set<String> bookingNotificationTypes = {
    'bookingCreated',
    'bookingConfirmed',
    'bookingRejected',
    'bookingCancelled',
    'bookingCompleted',
    'bookingNoShow',
    'appointmentReminder',
    'scheduleChanged',
  };

  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

  GoRouter? _router;

  String? _registeredUserId;
  bool _initialized = false;
  Map<String, dynamic>? _pendingTapData;
  int _nextLocalNotificationId = 0;

  /// Emits for every notification received while the app is in the foreground.
  ///
  /// `NotificationsCubit` listens to this to refresh the list / unread badge.
  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;

  /// Sets up local notifications, FCM listeners and the cold-start message.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly through Firebase Messaging so the
        // user only sees one prompt.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) =>
            _handlePayload(response.payload),
      );

      await _createAndroidChannel();
      await _requestPermission();

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _onMessageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForeground,
      );
      _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _handleTap(message.data));
      _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        _handleTokenRefresh,
      );

      // Cold start: the app was opened by tapping a notification. Preserve
      // the full payload (type + bookingId) so the tap can be routed to the
      // booking details once auth/navigation is ready.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingTapData = Map<String, dynamic>.from(initialMessage.data);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('NotificationService.initialize failed: $error\n$stackTrace');
    }
  }

  /// Lets the service navigate to the notifications screen once the router
  /// exists.
  ///
  /// A pending cold-start tap is intentionally *not* consumed here: the router
  /// is still on `/splash` while the session is being restored, so navigating
  /// now would be swallowed by the auth redirect. `main` consumes it once
  /// `AuthAuthenticated` is emitted.
  void attachRouter(GoRouter router) {
    _router = router;
  }

  /// Registers this device for [userId] and stores its token server-side.
  Future<void> registerDevice({required String userId}) async {
    final trimmedUserId = userId.trim();

    if (trimmedUserId.isEmpty) {
      return;
    }

    // Remembered so logout can remove the token even before signing out.
    _registeredUserId = trimmedUserId;

    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      await _repository.registerDeviceToken(
        userId: trimmedUserId,
        token: token,
        platform: _platformName(),
      );
    } on Object catch (error) {
      debugPrint('NotificationService.registerDevice failed: $error');
    }
  }

  /// Removes this device's token for the current user.
  ///
  /// Must be awaited before Firebase Auth signs out, otherwise the device
  /// document can no longer be deleted by the client (security rules).
  Future<void> unregisterDevice() async {
    final userId = _registeredUserId;

    _registeredUserId = null;

    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _repository.unregisterDeviceToken(userId: userId, token: token);
      }

      await _messaging.deleteToken();
    } on Object catch (error) {
      debugPrint('NotificationService.unregisterDevice failed: $error');
    }
  }

  /// Routes a stored cold-start tap once auth/navigation is ready.
  void tryConsumePendingTap() {
    final pending = _pendingTapData;

    if (pending == null) {
      return;
    }

    _navigateForTap(pending);
  }

  /// Releases the FCM listeners. The service normally lives for the whole app
  /// session, so this is only needed when the app tears down.
  Future<void> dispose() async {
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();

    _onMessageSubscription = null;
    _onMessageOpenedSubscription = null;
    _onTokenRefreshSubscription = null;

    await _foregroundMessages.close();
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permission denied by the user.');
      }
    } on Object catch (error) {
      debugPrint('NotificationService.requestPermission failed: $error');
    }
  }

  Future<void> _createAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              defaultChannelId,
              defaultChannelName,
              description: defaultChannelDescription,
              importance: Importance.high,
            ),
          );
    } on Object catch (error) {
      debugPrint('NotificationService.createChannel failed: $error');
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    // Keeps the notifications list / unread badge up to date while the app runs.
    _foregroundMessages.add(message);

    // iOS presents foreground notifications itself (see
    // setForegroundNotificationPresentationOptions); Android does not.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? _dataString(message.data, 'title');
    final body = notification?.body ?? _dataString(message.data, 'body');

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    try {
      await _localNotifications.show(
        id: _nextLocalNotificationId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            defaultChannelId,
            defaultChannelName,
            channelDescription: defaultChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } on Object catch (error) {
      debugPrint('NotificationService.showLocal failed: $error');
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    final userId = _registeredUserId;

    if (userId == null || userId.isEmpty || token.isEmpty) {
      return;
    }

    try {
      await _repository.registerDeviceToken(
        userId: userId,
        token: token,
        platform: _platformName(),
      );
    } on Object catch (error) {
      debugPrint('NotificationService.tokenRefresh failed: $error');
    }
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      _handleTap(const <String, dynamic>{});
      return;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        _handleTap(decoded);
        return;
      }
    } on FormatException catch (error) {
      debugPrint('NotificationService payload decode failed: $error');
    }

    _handleTap(const <String, dynamic>{});
  }

  void _handleTap(Map<String, dynamic> data) {
    debugPrint('Notification tapped: $data');
    _navigateForTap(data);
  }

  void _navigateForTap(Map<String, dynamic> data) {
    final router = _router;

    if (router == null || _firebaseAuth.currentUser == null) {
      // Not ready yet: keep the full payload pending until the session is
      // restored (cold start). It is consumed once AuthAuthenticated fires.
      _pendingTapData = Map<String, dynamic>.from(data);
      return;
    }

    _pendingTapData = null;

    final bookingId = _dataString(data, 'bookingId');
    final type = _dataString(data, 'type');

    if (bookingId.isNotEmpty && bookingNotificationTypes.contains(type)) {
      router.go(
        '$bookingDetailsRoute?bookingId=${Uri.encodeComponent(bookingId)}',
      );
      return;
    }

    router.go(notificationsRoute);
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    return defaultTargetPlatform.name;
  }

  String _dataString(Map<String, dynamic> data, String key) {
    final value = data[key];

    return value is String ? value : '';
  }
}
