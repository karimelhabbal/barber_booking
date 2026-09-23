import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
      emit(const BarberError('Barber user ID cannot be empty.'));
      return;
    }

    if (trimmedShopId.isEmpty) {
      emit(const BarberError('Barber shop ID cannot be empty.'));
      return;
    }

    emit(const BarberProfileLoading());

    try {
      final barber = await _repository.getBarberByUserAndShop(
        userId: trimmedUserId,
        barberShopId: trimmedShopId,
      );

      if (barber == null) {
        emit(const BarberError('Barber profile not found.'));
        return;
      }

      emit(BarberProfileLoaded(barber));
    } on Object catch (error) {
      emit(BarberError(error.toString()));
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
    } on Object catch (error) {
      emit(BarberError(error.toString()));
    }
  }

  Future<void> loadShopBarbers({required String barberShopId}) async {
    if (state is BarberLoading) {
      return;
    }

    final shopId = barberShopId.trim();

    if (shopId.isEmpty) {
      emit(const BarberError('Barber shop ID cannot be empty.'));
      return;
    }

    emit(const BarberLoading());

    try {
      final barbers = await _repository.getShopBarbers(barberShopId: shopId);

      emit(BarberLoaded(barbers));
    } on Object catch (error) {
      emit(BarberError(error.toString()));
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
      emit(const BarberError('Barber user ID cannot be empty.'));
      return;
    }

    if (trimmedShopId.isEmpty) {
      emit(const BarberError('Barber shop ID cannot be empty.'));
      return;
    }

    if (trimmedName.isEmpty) {
      emit(const BarberError('Barber name cannot be empty.'));
      return;
    }

    emit(const BarberCreating());

    try {
      final existingBarber = await _repository.getBarberByUserAndShop(
        userId: trimmedUserId,
        barberShopId: trimmedShopId,
      );

      if (existingBarber != null) {
        emit(
          const BarberError('This barber is already assigned to this shop.'),
        );
        return;
      }

      final barber = await _repository.createBarber(
        userId: trimmedUserId,
        barberShopId: trimmedShopId,
        name: trimmedName,
        phone: phone,
        imageUrl: imageUrl,
      );

      emit(BarberCreated(barber));
    } on Object catch (error) {
      emit(BarberError(error.toString()));
    }
  }

  Future<void> updateBarber(Barber barber) async {
    if (barber.id.trim().isEmpty) {
      emit(const BarberError('Barber ID cannot be empty.'));
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
    } on Object catch (error) {
      emit(BarberError(error.toString()));
    }
  }

  Future<void> deleteBarber({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const BarberError('Barber ID cannot be empty.'));
      return;
    }

    final currentState = state;

    final barberShopId = currentState is BarberLoaded
        ? _shopIdForBarber(currentState.barbers, trimmedBarberId)
        : null;

    emit(BarberDeleting(trimmedBarberId));

    try {
      await _repository.deleteBarber(barberId: trimmedBarberId);
    } on Object catch (error) {
      emit(BarberError(error.toString()));
      return;
    }

    emit(BarberDeleted(trimmedBarberId));

    if (barberShopId != null) {
      await loadShopBarbers(barberShopId: barberShopId);
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
