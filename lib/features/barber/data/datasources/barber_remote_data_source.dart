import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/barber_candidate_model.dart';
import '../models/barber_model.dart';

enum BarberDataSourceErrorCode {
  barberIdEmpty,
  userIdEmpty,
  shopIdEmpty,
  nameEmpty,
  userNotFound,
  userNotBarber,
  assignedAnotherShop,
  assignedThisShop,
  barberNotFound,
  barberUserIdMissing,
  barberShopIdMissing,
}

class BarberDataSourceException implements Exception {
  const BarberDataSourceException(this.code);

  final BarberDataSourceErrorCode code;
}

abstract interface class BarberRemoteDataSource {
  Future<BarberModel?> getBarber({required String barberId});

  Future<List<BarberModel>> getShopBarbers({required String barberShopId});

  Future<BarberModel> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  });

  Future<void> updateBarber(BarberModel barber);

  Future<void> deleteBarber({required String barberId});

  Future<List<BarberCandidateModel>> getBarberCandidates();

  Future<BarberModel?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  });
}

class BarberRemoteDataSourceImpl implements BarberRemoteDataSource {
  BarberRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _barbersCollection =>
      _firestore.collection('barbers');

  @override
  Future<BarberModel?> getBarber({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberIdEmpty,
      );
    }

    final document = await _barbersCollection.doc(trimmedBarberId).get();

    if (!document.exists) return null;

    return BarberModel.fromFirestore(document);
  }

  @override
  Future<List<BarberModel>> getShopBarbers({
    required String barberShopId,
  }) async {
    final trimmedBarberShopId = barberShopId.trim();

    if (trimmedBarberShopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }

    final snapshot = await _barbersCollection
        .where('barberShopId', isEqualTo: trimmedBarberShopId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map(BarberModel.fromFirestore).toList();
  }

  @override
  Future<BarberModel> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedBarberShopId = barberShopId.trim();
    final trimmedName = name.trim();

    if (trimmedUserId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userIdEmpty,
      );
    }

    if (trimmedBarberShopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }

    if (trimmedName.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.nameEmpty,
      );
    }

    final userReference = _firestore.collection('users').doc(trimmedUserId);

    final userSnapshot = await userReference.get();

    if (!userSnapshot.exists) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotFound,
      );
    }

    final userData = userSnapshot.data();

    if (userData?['role'] != 'barber') {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotBarber,
      );
    }

    final currentShopId = (userData?['barberShopId'] as String?)?.trim();

    if (currentShopId != null &&
        currentShopId.isNotEmpty &&
        currentShopId != trimmedBarberShopId) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.assignedAnotherShop,
      );
    }

    final existingBarber = await getBarberByUserAndShop(
      userId: trimmedUserId,
      barberShopId: trimmedBarberShopId,
    );

    if (existingBarber != null && existingBarber.isActive) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.assignedThisShop,
      );
    }

    final now = DateTime.now();
    final batch = _firestore.batch();

    if (existingBarber != null) {
      final barberReference = _barbersCollection.doc(existingBarber.id);

      batch.set(barberReference, {
        'userId': trimmedUserId,
        'barberShopId': trimmedBarberShopId,
        'name': trimmedName,
        'phone': phone?.trim(),
        'imageUrl': imageUrl?.trim(),
        'isActive': true,
        'createdAt': Timestamp.fromDate(existingBarber.createdAt),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      if (currentShopId == null || currentShopId.isEmpty) {
        batch.update(userReference, {'barberShopId': trimmedBarberShopId});
      }

      await batch.commit();

      return BarberModel(
        id: existingBarber.id,
        userId: trimmedUserId,
        barberShopId: trimmedBarberShopId,
        name: trimmedName,
        phone: phone?.trim(),
        imageUrl: imageUrl?.trim(),
        isActive: true,
        createdAt: existingBarber.createdAt,
        updatedAt: now,
      );
    }

    final reference = _barbersCollection.doc();

    final barber = BarberModel(
      id: reference.id,
      userId: trimmedUserId,
      barberShopId: trimmedBarberShopId,
      name: trimmedName,
      phone: phone?.trim(),
      imageUrl: imageUrl?.trim(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    batch.set(reference, barber.toFirestore());

    if (currentShopId == null || currentShopId.isEmpty) {
      batch.update(userReference, {'barberShopId': trimmedBarberShopId});
    }

    await batch.commit();

    return barber;
  }

  @override
  Future<void> updateBarber(BarberModel barber) async {
    await _barbersCollection
        .doc(barber.id)
        .set(barber.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteBarber({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberIdEmpty,
      );
    }

    final barberReference = _barbersCollection.doc(trimmedBarberId);

    final barberSnapshot = await barberReference.get();

    if (!barberSnapshot.exists) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberNotFound,
      );
    }

    final barberData = barberSnapshot.data();

    final userId = (barberData?['userId'] as String?)?.trim();
    final barberShopId = (barberData?['barberShopId'] as String?)?.trim();

    if (userId == null || userId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberUserIdMissing,
      );
    }

    if (barberShopId == null || barberShopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberShopIdMissing,
      );
    }

    final userReference = _firestore.collection('users').doc(userId);

    final userSnapshot = await userReference.get();

    if (!userSnapshot.exists) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotFound,
      );
    }

    final userData = userSnapshot.data();

    final currentUserShopId = (userData?['barberShopId'] as String?)?.trim();

    final batch = _firestore.batch();

    batch.set(barberReference, {
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    if (currentUserShopId == barberShopId) {
      batch.update(userReference, {'barberShopId': null});
    }

    await batch.commit();
  }

  @override
  Future<List<BarberCandidateModel>> getBarberCandidates() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'barber')
        .where('barberShopId', isEqualTo: null)
        .get();

    return snapshot.docs.map(BarberCandidateModel.fromFirestore).toList();
  }

  @override
  Future<BarberModel?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedBarberShopId = barberShopId.trim();

    if (trimmedUserId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userIdEmpty,
      );
    }

    if (trimmedBarberShopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }

    final snapshot = await _barbersCollection
        .where('userId', isEqualTo: trimmedUserId)
        .where('barberShopId', isEqualTo: trimmedBarberShopId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return BarberModel.fromFirestore(snapshot.docs.first);
  }
}
