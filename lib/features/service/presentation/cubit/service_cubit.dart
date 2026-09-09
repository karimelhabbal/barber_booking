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

  String _mapError(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Failed to load services.';
    }

    return message;
  }
}
