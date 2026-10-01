import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<NotificationModel>> loadNotifications({
    required String recipientId,
  });

  Future<void> markAsRead({required String notificationId});

  Future<void> markAllAsRead({required String recipientId});

  /// Stores/refreshes the FCM registration token of the current device under
  /// `users/{userId}/devices/{token}`.
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  });

  /// Removes the FCM registration token of the current device. Called before
  /// signing out so the previous account stops receiving pushes on this device.
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> _devicesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('devices');
  }

  @override
  Future<List<NotificationModel>> loadNotifications({
    required String recipientId,
  }) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(NotificationModel.fromFirestore)
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead({required String recipientId}) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedToken = token.trim();

    if (trimmedUserId.isEmpty || trimmedToken.isEmpty) {
      return;
    }

    await _devicesCollection(trimmedUserId).doc(trimmedToken).set({
      'token': trimmedToken,
      'platform': platform,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedToken = token.trim();

    if (trimmedUserId.isEmpty || trimmedToken.isEmpty) {
      return;
    }

    await _devicesCollection(trimmedUserId).doc(trimmedToken).delete();
  }
}
