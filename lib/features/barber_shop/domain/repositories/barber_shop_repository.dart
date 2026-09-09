import '../entities/barber_shop.dart';

abstract interface class BarberShopRepository {
  Future<BarberShop?> getShop({required String shopId});

  Future<BarberShop?> getOwnerShop({required String ownerId});

  Future<List<BarberShop>> getActiveShops();

  Future<BarberShop> createShop({
    required String ownerId,
    required String name,
    String? phone,
    String? address,
    String? description,
    String? imageUrl,
    String timezone = 'Africa/Cairo',
  });

  Future<void> updateShop(BarberShop shop);
}
