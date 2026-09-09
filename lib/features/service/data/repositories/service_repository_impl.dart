import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_data_source.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl({required this._remoteDataSource});

  final ServiceRemoteDataSource _remoteDataSource;

  @override
  Future<Service?> getService({
    required String shopId,
    required String serviceId,
  }) {
    return _remoteDataSource.getService(shopId: shopId, serviceId: serviceId);
  }

  @override
  Future<List<Service>> getShopServices({required String shopId}) {
    return _remoteDataSource.getShopServices(shopId: shopId);
  }

  @override
  Future<List<Service>> getActiveShopServices({required String shopId}) {
    return _remoteDataSource.getActiveShopServices(shopId: shopId);
  }

  @override
  Future<Service> createService({
    required String shopId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
  }) {
    throw UnimplementedError(
      'Creating a service requires Owner authorization.',
    );
  }

  @override
  Future<void> updateService(Service service) {
    throw UnimplementedError(
      'Updating a service requires Owner authorization.',
    );
  }
}
