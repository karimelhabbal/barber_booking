import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_data_source.dart';
import '../models/service_model.dart';

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
    return _remoteDataSource.createService(
      shopId: shopId,
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
    );
  }

  @override
  Future<void> updateService(Service service) {
    return _remoteDataSource.updateService(ServiceModel.fromEntity(service));
  }

  @override
  Future<void> deleteService({
    required String shopId,
    required String serviceId,
  }) {
    return _remoteDataSource.deleteService(
      shopId: shopId,
      serviceId: serviceId,
    );
  }
}
