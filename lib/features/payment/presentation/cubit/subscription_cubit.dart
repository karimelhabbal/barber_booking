import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'subscription_state.dart';

/// Owner SaaS subscription (Owner -> Platform). Activation only ever comes from the server.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repo) : super(const SubscriptionState());

  final SubscriptionRepository _repo;
  StreamSubscription<OwnerSubscription?>? _subSub;
  StreamSubscription<SubscriptionPayment?>? _paySub;
  Timer? _slowTimer;

  Future<void> load(String ownerId) async {
    emit(state.copyWith(flow: SubscriptionFlow.loading, clearFailure: true));
    try {
      final plans = await _repo.getActivePlans();
      _subSub?.cancel();
      _subSub = _repo.watchSubscription(ownerId).listen((s) {
        if (isClosed) return;
        emit(state.copyWith(subscription: s));
      });
      emit(state.copyWith(flow: SubscriptionFlow.ready, plans: plans));
    } on PaymentFailure catch (f) {
      emit(state.copyWith(flow: SubscriptionFlow.failed, failure: f));
    }
  }

  Future<void> subscribe(String planId) async {
    if (state.flow != SubscriptionFlow.ready) return;
    if (!_isValidEmail(state.billingEmail)) {
      emit(
        state.copyWith(
          flow: SubscriptionFlow.failed,
          failure: const PaymentFailure(PaymentFailureCode.invalidArgument),
        ),
      );
      return;
    }
    emit(state.copyWith(flow: SubscriptionFlow.submitting, clearFailure: true));
    try {
      final session = await _repo.startCheckout(planId, state.billingEmail);
      if (session.checkoutUrl == null) {
        emit(
          state.copyWith(
            flow: SubscriptionFlow.failed,
            failure: const PaymentFailure(PaymentFailureCode.unknown),
          ),
        );
        return;
      }
      emit(
        state.copyWith(flow: SubscriptionFlow.checkoutReady, session: session),
      );
    } on PaymentFailure catch (f) {
      emit(state.copyWith(flow: SubscriptionFlow.failed, failure: f));
    }
  }

  void setBillingEmail(String email) {
    if (state.flow != SubscriptionFlow.ready) return;
    emit(state.copyWith(billingEmail: email));
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  void onCheckoutClosed() {
    final session = state.session;
    if (session == null) return;
    _paySub?.cancel();
    _slowTimer?.cancel();
    emit(
      state.copyWith(flow: SubscriptionFlow.tracking, verifyingTooLong: false),
    );
    _slowTimer = Timer(const Duration(seconds: 45), () {
      if (!isClosed && state.flow == SubscriptionFlow.tracking) {
        emit(state.copyWith(verifyingTooLong: true));
      }
    });
    _paySub = _repo.watchSubscriptionPayment(session.paymentId).listen((p) {
      if (isClosed || p == null) return;
      if (p.status == SubscriptionPaymentStatus.paid) {
        _cancelTracking();
        emit(state.copyWith(flow: SubscriptionFlow.activated));
      } else if (p.status == SubscriptionPaymentStatus.failed ||
          p.status == SubscriptionPaymentStatus.expired ||
          p.status == SubscriptionPaymentStatus.cancelled) {
        _cancelTracking();
        emit(state.copyWith(flow: SubscriptionFlow.failed));
      }
    });
  }

  void backToReady() {
    _cancelTracking();
    emit(
      state.copyWith(
        flow: SubscriptionFlow.ready,
        clearFailure: true,
        clearSession: true,
        verifyingTooLong: false,
      ),
    );
  }

  void _cancelTracking() {
    _slowTimer?.cancel();
    _slowTimer = null;
    _paySub?.cancel();
    _paySub = null;
  }

  @override
  Future<void> close() {
    _cancelTracking();
    _subSub?.cancel();
    return super.close();
  }
}
