import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_model.dart';

abstract interface class ServiceRemoteDataSource {
  Future<ServiceModel?> getService({
    required String shopId,
    required String serviceId,
  });

  Future<List<ServiceModel>> getShopServices({required String shopId});

  Future<List<ServiceModel>> getActiveShopServices({required String shopId});

  Future<ServiceModel> createService({
    required String shopId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
  });

  Future<void> updateService(ServiceModel service);

  Future<void> deleteService({
    required String shopId,
    required String serviceId,
  });
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  ServiceRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _servicesCollection(String shopId) {
    return _firestore
        .collection('barberShops')
        .doc(shopId)
        .collection('services');
  }

  @override
  Future<ServiceModel?> getService({
    required String shopId,
    required String serviceId,
  }) async {
    final document = await _servicesCollection(shopId).doc(serviceId).get();

    if (!document.exists) {
      return null;
    }

    return ServiceModel.fromFirestore(document);
  }

  @override
  Future<List<ServiceModel>> getShopServices({required String shopId}) async {
    final snapshot = await _servicesCollection(shopId).get();

    return snapshot.docs.map(ServiceModel.fromFirestore).toList();
  }

  @override
  Future<List<ServiceModel>> getActiveShopServices({
    required String shopId,
  }) async {
    final snapshot = await _servicesCollection(shopId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map(ServiceModel.fromFirestore).toList();
  }

  @override
  Future<ServiceModel> createService({
    required String shopId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
  }) async {
    final reference = _servicesCollection(shopId).doc();
    final now = DateTime.now();

    final service = ServiceModel(
      id: reference.id,
      barberShopId: shopId,
      name: name.trim(),
      description: description?.trim(),
      durationMinutes: durationMinutes,
      price: price,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await reference.set(service.toFirestore());

    return service;
  }

  @override
  Future<void> updateService(ServiceModel service) async {
    await _servicesCollection(service.barberShopId)
        .doc(service.id)
        .set(service.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteService({
    required String shopId,
    required String serviceId,
  }) {
    return _servicesCollection(shopId).doc(serviceId).delete();
  }
}
