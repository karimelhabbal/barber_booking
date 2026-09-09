import '../entities/service.dart';

abstract interface class ServiceRepository {
  Future<Service?> getService({
    required String shopId,
    required String serviceId,
  });

  Future<List<Service>> getShopServices({required String shopId});

  Future<List<Service>> getActiveShopServices({required String shopId});

  Future<Service> createService({
    required String shopId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
  });

  Future<void> updateService(Service service);
}
