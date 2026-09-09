import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/barber_candidate_model.dart';
import '../models/barber_model.dart';

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
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final document = await _barbersCollection.doc(trimmedBarberId).get();

    if (!document.exists) {
      return null;
    }

    return BarberModel.fromFirestore(document);
  }

  @override
  Future<List<BarberModel>> getShopBarbers({
    required String barberShopId,
  }) async {
    final trimmedBarberShopId = barberShopId.trim();

    if (trimmedBarberShopId.isEmpty) {
      throw ArgumentError('Barber shop ID cannot be empty.');
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
      throw ArgumentError('User ID cannot be empty.');
    }

    if (trimmedBarberShopId.isEmpty) {
      throw ArgumentError('Barber shop ID cannot be empty.');
    }

    if (trimmedName.isEmpty) {
      throw ArgumentError('Barber name cannot be empty.');
    }

    final reference = _barbersCollection.doc();

    final now = DateTime.now();

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

    await reference.set(barber.toFirestore());

    return barber;
  }

  @override
  Future<void> updateBarber(BarberModel barber) async {
    await _barbersCollection
        .doc(barber.id)
        .set(barber.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<List<BarberCandidateModel>> getBarberCandidates() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'barber')
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
      throw ArgumentError('User ID cannot be empty.');
    }

    if (trimmedBarberShopId.isEmpty) {
      throw ArgumentError('Barber shop ID cannot be empty.');
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
