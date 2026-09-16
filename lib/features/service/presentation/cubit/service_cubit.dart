import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import 'service_state.dart';

class ServiceCubit extends Cubit<ServiceState> {
  ServiceCubit({required this._repository}) : super(const ServiceInitial());

  final ServiceRepository _repository;

  Future<void> loadActiveShopServices({required String shopId}) async {
    final normalizedShopId = shopId.trim();

    if (normalizedShopId.isEmpty) {
      emit(const ServiceError('Barber shop ID is required.'));
      return;
    }

    emit(const ServiceLoading());

    try {
      final services = await _repository.getActiveShopServices(
        shopId: normalizedShopId,
      );

      services.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      emit(ServiceLoaded(List<Service>.unmodifiable(services)));
    } catch (e) {
      emit(ServiceError(_mapError(e)));
    }
  }

  Future<void> loadShopServices({required String shopId}) async {
    final normalizedShopId = shopId.trim();

    if (normalizedShopId.isEmpty) {
      emit(const ServiceError('Barber shop ID is required.'));
      return;
    }

    emit(const ServiceLoading());

    try {
      final services = await _repository.getShopServices(
        shopId: normalizedShopId,
      );
      _sortServices(services);
      emit(ServiceLoaded(List<Service>.unmodifiable(services)));
    } catch (e) {
      emit(ServiceError(_mapError(e)));
    }
  }

  Future<void> createService({
    required String shopId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
  }) async {
    final validationError = _validateService(
      shopId: shopId,
      name: name,
      durationMinutes: durationMinutes,
      price: price,
    );

    if (validationError != null) {
      emit(ServiceError(validationError));
      return;
    }

    emit(const ServiceCreating());

    try {
      final service = await _repository.createService(
        shopId: shopId.trim(),
        name: name.trim(),
        description: description,
        durationMinutes: durationMinutes,
        price: price,
      );
      emit(ServiceCreated(service));
    } catch (e) {
      emit(ServiceError(_mapError(e)));
    }
  }

  Future<void> updateService(Service service) async {
    final validationError = _validateService(
      shopId: service.barberShopId,
      name: service.name,
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

    if (validationError != null || service.id.trim().isEmpty) {
      emit(ServiceError(validationError ?? 'Service ID is required.'));
      return;
    }

    emit(ServiceUpdating(service));

    try {
      await _repository.updateService(service);
      emit(ServiceUpdated(service));
    } catch (e) {
      emit(ServiceError(_mapError(e)));
    }
  }

  Future<void> deleteService({
    required String shopId,
    required String serviceId,
  }) async {
    final normalizedShopId = shopId.trim();
    final normalizedServiceId = serviceId.trim();

    if (normalizedShopId.isEmpty || normalizedServiceId.isEmpty) {
      emit(const ServiceError('Shop and service IDs are required.'));
      return;
    }

    emit(ServiceDeleting(normalizedServiceId));

    try {
      await _repository.deleteService(
        shopId: normalizedShopId,
        serviceId: normalizedServiceId,
      );
      emit(ServiceDeleted(normalizedServiceId));
    } catch (e) {
      emit(ServiceError(_mapError(e)));
    }
  }

  String? _validateService({
    required String shopId,
    required String name,
    required int durationMinutes,
    required double price,
  }) {
    if (shopId.trim().isEmpty) {
      return 'Barber shop ID is required.';
    }
    if (name.trim().isEmpty) {
      return 'Service name is required.';
    }
    if (durationMinutes <= 0 || durationMinutes % 5 != 0) {
      return 'Service duration must be a positive multiple of 5 minutes.';
    }
    if (price < 0) {
      return 'Service price cannot be negative.';
    }
    return null;
  }

  void _sortServices(List<Service> services) {
    services.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  String _mapError(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Failed to load services.';
    }

    return message;
  }
}
