import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/barber_shop.dart';
import '../../domain/repositories/barber_shop_repository.dart';

part 'barber_shop_state.dart';

class BarberShopCubit extends Cubit<BarberShopState> {
  BarberShopCubit({required this._repository})
    : super(const BarberShopInitial());

  final BarberShopRepository _repository;

  Future<void> loadActiveShops() async {
    if (state is BarberShopLoading) {
      return;
    }

    emit(const BarberShopLoading());

    try {
      final shops = await _repository.getActiveShops();

      emit(BarberShopLoaded(shops));
    } on Object catch (error) {
      emit(BarberShopError(error.toString()));
    }
  }

  Future<void> loadOwnerShop({required String ownerId}) async {
    emit(const BarberShopOwnerLoading());

    try {
      final shop = await _repository.getOwnerShop(ownerId: ownerId);

      emit(BarberShopOwnerLoaded(shop));
    } on Object catch (error) {
      emit(BarberShopError(error.toString()));
    }
  }

  Future<void> createShop({
    required String ownerId,
    required String name,
    String? phone,
    String? address,
    String? description,
    String? imageUrl,
    String timezone = 'Africa/Cairo',
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      emit(const BarberShopError('Barber shop name cannot be empty.'));
      return;
    }

    emit(const BarberShopCreating());

    try {
      final shop = await _repository.createShop(
        ownerId: ownerId,
        name: trimmedName,
        phone: phone,
        address: address,
        description: description,
        imageUrl: imageUrl,
        timezone: timezone,
      );

      emit(BarberShopCreated(shop));
    } on Object catch (error) {
      emit(BarberShopError(error.toString()));
    }
  }
}
