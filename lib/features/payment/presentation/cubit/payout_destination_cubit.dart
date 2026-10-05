import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payout_destination.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/payout_destination_repository.dart';

enum PayoutDestinationFlow { loading, ready, saving, saved, failed }

class PayoutDestinationState extends Equatable {
  const PayoutDestinationState({this.flow = PayoutDestinationFlow.loading, this.destination, this.failure});

  final PayoutDestinationFlow flow;
  final PayoutDestination? destination;
  final PaymentFailure? failure;

  PayoutDestinationState copyWith({
    PayoutDestinationFlow? flow,
    PayoutDestination? destination,
    PaymentFailure? failure,
    bool clearFailure = false,
  }) =>
      PayoutDestinationState(
        flow: flow ?? this.flow,
        destination: destination ?? this.destination,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [flow, destination, failure];
}

class PayoutDestinationCubit extends Cubit<PayoutDestinationState> {
  PayoutDestinationCubit(this._repo) : super(const PayoutDestinationState());

  final PayoutDestinationRepository _repo;
  StreamSubscription<PayoutDestination?>? _sub;

  void load(String ownerId) {
    _sub?.cancel();
    _sub = _repo.watch(ownerId).listen((d) {
      if (isClosed) return;
      if (state.flow == PayoutDestinationFlow.loading || state.flow == PayoutDestinationFlow.ready) {
        emit(state.copyWith(flow: PayoutDestinationFlow.ready, destination: d));
      } else {
        emit(state.copyWith(destination: d));
      }
    }, onError: (Object _) {
      if (isClosed) return;
      emit(state.copyWith(flow: PayoutDestinationFlow.failed, failure: const PaymentFailure(PaymentFailureCode.unavailable)));
    });
  }

  Future<void> save(PayoutDestination destination) async {
    emit(state.copyWith(flow: PayoutDestinationFlow.saving, clearFailure: true));
    try {
      await _repo.save(destination);
      emit(state.copyWith(flow: PayoutDestinationFlow.saved));
    } on PaymentFailure catch (f) {
      emit(state.copyWith(flow: PayoutDestinationFlow.failed, failure: f));
    }
  }

  void acknowledge() => emit(state.copyWith(flow: PayoutDestinationFlow.ready, clearFailure: true));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
