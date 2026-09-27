import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/barber_remote_data_source.dart';
import '../../domain/entities/barber.dart';
import '../../domain/entities/barber_candidate.dart';
import '../../domain/repositories/barber_repository.dart';

part 'barber_state.dart';

class BarberCubit extends Cubit<BarberState> {
  BarberCubit({required this._repository}) : super(const BarberInitial());

  final BarberRepository _repository;

  Future<void> loadCurrentBarber({
    required String userId,
    required String barberShopId,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedShopId = barberShopId.trim();

    if (trimmedUserId.isEmpty) {
      emit(const BarberError(BarberErrorCode.userIdEmpty));
      return;
    }

    if (trimmedShopId.isEmpty) {
      emit(const BarberError(BarberErrorCode.shopIdEmpty));
      return;
    }

    emit(const BarberProfileLoading());

    try {
      final barber = await _repository.getBarberByUserAndShop(
        userId: trimmedUserId,
        barberShopId: trimmedShopId,
      );

      if (barber == null) {
        emit(const BarberError(BarberErrorCode.profileNotFound));
        return;
      }

      emit(BarberProfileLoaded(barber));
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
    }
  }

  Future<void> loadBarberCandidates() async {
    if (state is BarberCandidatesLoading) {
      return;
    }

    emit(const BarberCandidatesLoading());

    try {
      final candidates = await _repository.getBarberCandidates();

      emit(BarberCandidatesLoaded(candidates));
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
    }
  }

  Future<void> loadShopBarbers({required String barberShopId}) async {
    if (state is BarberLoading) {
      return;
    }

    final shopId = barberShopId.trim();

    if (shopId.isEmpty) {
      emit(const BarberError(BarberErrorCode.shopIdEmpty));
      return;
    }

    emit(const BarberLoading());

    try {
      final barbers = await _repository.getShopBarbers(barberShopId: shopId);

      emit(BarberLoaded(barbers));
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
    }
  }

  Future<void> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedShopId = barberShopId.trim();
    final trimmedName = name.trim();

    if (trimmedUserId.isEmpty) {
      emit(const BarberError(BarberErrorCode.userIdEmpty));
      return;
    }

    if (trimmedShopId.isEmpty) {
      emit(const BarberError(BarberErrorCode.shopIdEmpty));
      return;
    }

    if (trimmedName.isEmpty) {
      emit(const BarberError(BarberErrorCode.nameEmpty));
      return;
    }

    emit(const BarberCreating());

    try {
      final barber = await _repository.createBarber(
        userId: trimmedUserId,
        barberShopId: trimmedShopId,
        name: trimmedName,
        phone: phone,
        imageUrl: imageUrl,
      );

      emit(BarberCreated(barber));
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
    }
  }

  Future<void> updateBarber(Barber barber) async {
    if (barber.id.trim().isEmpty) {
      emit(const BarberError(BarberErrorCode.barberIdEmpty));
      return;
    }

    final currentState = state;

    try {
      await _repository.updateBarber(barber);

      if (currentState is BarberLoaded) {
        final updatedBarbers = currentState.barbers.map((item) {
          if (item.id == barber.id) {
            return barber;
          }

          return item;
        }).toList();

        emit(BarberLoaded(updatedBarbers));
        return;
      }

      emit(BarberUpdated(barber));
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
    }
  }

  Future<void> deleteBarber({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const BarberError(BarberErrorCode.barberIdEmpty));
      return;
    }

    final currentState = state;

    final barberShopId = currentState is BarberLoaded
        ? _shopIdForBarber(currentState.barbers, trimmedBarberId)
        : null;

    emit(BarberDeleting(trimmedBarberId));

    try {
      await _repository.deleteBarber(barberId: trimmedBarberId);
    } on BarberDataSourceException catch (error) {
      emit(_fromDataSourceError(error));
      return;
    } on Object catch (error) {
      emit(
        BarberError(BarberErrorCode.unknown, fallbackMessage: error.toString()),
      );
      return;
    }

    emit(BarberDeleted(trimmedBarberId));

    if (barberShopId != null) {
      await loadShopBarbers(barberShopId: barberShopId);
    }
  }

  BarberError _fromDataSourceError(BarberDataSourceException error) {
    return BarberError(_mapDataSourceErrorCode(error.code));
  }

  BarberErrorCode _mapDataSourceErrorCode(BarberDataSourceErrorCode code) {
    switch (code) {
      case BarberDataSourceErrorCode.barberIdEmpty:
        return BarberErrorCode.barberIdEmpty;

      case BarberDataSourceErrorCode.userIdEmpty:
        return BarberErrorCode.userIdEmpty;

      case BarberDataSourceErrorCode.shopIdEmpty:
        return BarberErrorCode.shopIdEmpty;

      case BarberDataSourceErrorCode.nameEmpty:
        return BarberErrorCode.nameEmpty;

      case BarberDataSourceErrorCode.userNotFound:
        return BarberErrorCode.userNotFound;

      case BarberDataSourceErrorCode.userNotBarber:
        return BarberErrorCode.userNotBarber;

      case BarberDataSourceErrorCode.assignedAnotherShop:
        return BarberErrorCode.assignedAnotherShop;

      case BarberDataSourceErrorCode.assignedThisShop:
        return BarberErrorCode.assignedThisShop;

      case BarberDataSourceErrorCode.barberNotFound:
        return BarberErrorCode.barberNotFound;

      case BarberDataSourceErrorCode.barberUserIdMissing:
        return BarberErrorCode.barberUserIdMissing;

      case BarberDataSourceErrorCode.barberShopIdMissing:
        return BarberErrorCode.barberShopIdMissing;
    }
  }

  String? _shopIdForBarber(List<Barber> barbers, String barberId) {
    for (final barber in barbers) {
      if (barber.id == barberId) {
        return barber.barberShopId;
      }
    }

    return null;
  }
}
