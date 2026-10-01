import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<NotificationModel>> loadNotifications({
    required String recipientId,
  });

  Future<void> markAsRead({required String notificationId});

  Future<void> markAllAsRead({required String recipientId});
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

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
}
