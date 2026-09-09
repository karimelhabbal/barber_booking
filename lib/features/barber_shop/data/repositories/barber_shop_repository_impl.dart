import '../../domain/entities/barber_shop.dart';
import '../../domain/repositories/barber_shop_repository.dart';
import '../datasources/barber_shop_remote_data_source.dart';
import '../models/barber_shop_model.dart';

class BarberShopRepositoryImpl implements BarberShopRepository {
  BarberShopRepositoryImpl({required this._remoteDataSource});

  final BarberShopRemoteDataSource _remoteDataSource;

  @override
  Future<BarberShop?> getShop({required String shopId}) {
    return _remoteDataSource.getShop(shopId: shopId);
  }

  @override
  Future<BarberShop?> getOwnerShop({required String ownerId}) {
    return _remoteDataSource.getOwnerShop(ownerId: ownerId);
  }

  @override
  Future<List<BarberShop>> getActiveShops() {
    return _remoteDataSource.getActiveShops();
  }

  @override
  Future<BarberShop> createShop({
    required String ownerId,
    required String name,
    String? phone,
    String? address,
    String? description,
    String? imageUrl,
    String timezone = 'Africa/Cairo',
  }) {
    return _remoteDataSource.createShop(
      ownerId: ownerId,
      name: name,
      phone: phone,
      address: address,
      description: description,
      imageUrl: imageUrl,
      timezone: timezone,
    );
  }

  @override
  Future<void> updateShop(BarberShop shop) {
    return _remoteDataSource.updateShop(BarberShopModel.fromEntity(shop));
  }
}
