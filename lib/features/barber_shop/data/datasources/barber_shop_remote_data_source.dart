import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/barber_shop_model.dart';

abstract interface class BarberShopRemoteDataSource {
  Future<BarberShopModel?> getShop({required String shopId});

  Future<BarberShopModel?> getOwnerShop({required String ownerId});

  Future<List<BarberShopModel>> getActiveShops();

  Future<BarberShopModel> createShop({
    required String ownerId,
    required String name,
    String? phone,
    String? address,
    String? description,
    String? imageUrl,
    required String timezone,
  });

  Future<void> updateShop(BarberShopModel shop);
}

class BarberShopRemoteDataSourceImpl implements BarberShopRemoteDataSource {
  BarberShopRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _firestore.collection('barberShops');

  @override
  Future<BarberShopModel?> getShop({required String shopId}) async {
    final document = await _shopsCollection.doc(shopId).get();

    if (!document.exists) {
      return null;
    }

    return BarberShopModel.fromFirestore(document);
  }

  @override
  Future<BarberShopModel?> getOwnerShop({required String ownerId}) async {
    final snapshot = await _shopsCollection
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return BarberShopModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<List<BarberShopModel>> getActiveShops() async {
    final snapshot = await _shopsCollection
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map(BarberShopModel.fromFirestore).toList();
  }

  @override
  Future<BarberShopModel> createShop({
    required String ownerId,
    required String name,
    String? phone,
    String? address,
    String? description,
    String? imageUrl,
    required String timezone,
  }) async {
    final reference = _shopsCollection.doc();
    final now = DateTime.now();

    final shop = BarberShopModel(
      id: reference.id,
      name: name.trim(),
      ownerId: ownerId,
      phone: phone?.trim(),
      address: address?.trim(),
      description: description?.trim(),
      imageUrl: imageUrl?.trim(),
      timezone: timezone,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await reference.set(shop.toFirestore());

    return shop;
  }

  @override
  Future<void> updateShop(BarberShopModel shop) async {
    await _shopsCollection
        .doc(shop.id)
        .set(shop.toFirestore(), SetOptions(merge: true));
  }
}
