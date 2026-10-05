import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_payment.dart';
import '../../domain/entities/payment_enums.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/booking_payment_repository.dart';
import 'booking_payment_state.dart';

/// Drives the customer payment flow. It NEVER decides that a payment succeeded:
/// success is only reflected from the server-written `bookingPayments/{id}` document.
class BookingPaymentCubit extends Cubit<BookingPaymentState> {
  BookingPaymentCubit(this._repo) : super(const BookingPaymentState());

  final BookingPaymentRepository _repo;
  StreamSubscription<BookingPayment?>? _sub;
  Timer? _slowTimer;
  String? _trackedPaymentId;

  static const Duration slowAfter = Duration(seconds: 45);

  Future<void> load(String shopId) async {
    emit(state.copyWith(flow: BookingPaymentFlow.loading, clearFailure: true));
    try {
      final options = await _repo.getShopPaymentOptions(shopId);
      final selected = options.onlineEnabled
          ? PaymentMethod.online
          : (options.cashEnabled ? PaymentMethod.cash : null);
      emit(
        state.copyWith(
          flow: BookingPaymentFlow.ready,
          options: options,
          selected: selected,
        ),
      );
    } on PaymentFailure catch (f) {
      emit(state.copyWith(flow: BookingPaymentFlow.failed, failure: f));
    }
  }

  void select(PaymentMethod method) {
    if (state.flow != BookingPaymentFlow.ready) return;
    final o = state.options;
    if (o == null) return;
    if (method == PaymentMethod.online && !o.onlineEnabled) return;
    if (method == PaymentMethod.cash && !o.cashEnabled) return;
    emit(state.copyWith(selected: method));
  }

  bool get hasValidBillingEmail => _isValidEmail(state.billingEmail);

  void setBillingEmail(String email) {
    if (state.flow != BookingPaymentFlow.ready) return;
    emit(state.copyWith(billingEmail: email));
  }

  Future<void> submit(String bookingId) async {
    final method = state.selected;
    if (method == null || state.flow != BookingPaymentFlow.ready) return;
    if (method == PaymentMethod.online && !hasValidBillingEmail) {
      emit(
        state.copyWith(
          flow: BookingPaymentFlow.failed,
          failure: const PaymentFailure(PaymentFailureCode.invalidArgument),
        ),
      );
      return;
    }
    emit(
      state.copyWith(flow: BookingPaymentFlow.submitting, clearFailure: true),
    );
    try {
      final session = await _repo.createBookingPayment(
        bookingId: bookingId,
        method: method,
        billingEmail: state.billingEmail,
      );
      if (method == PaymentMethod.online && session.checkoutUrl != null) {
        emit(
          state.copyWith(
            flow: BookingPaymentFlow.checkoutReady,
            session: session,
          ),
        );
      } else {
        _track(session.paymentId);
      }
    } on PaymentFailure catch (f) {
      emit(state.copyWith(flow: BookingPaymentFlow.failed, failure: f));
    }
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  /// Called when the checkout WebView is closed (success, failure or back). We verify server-side.
  void onCheckoutClosed() {
    final session = state.session;
    if (session == null) return;
    _track(session.paymentId);
  }

  void backToReady() {
    _cancelTracking();
    emit(
      state.copyWith(
        flow: BookingPaymentFlow.ready,
        clearFailure: true,
        clearSession: true,
        verifyingTooLong: false,
      ),
    );
  }

  Future<void> refresh() async {
    final id = _trackedPaymentId;
    if (id == null) return;
    try {
      await _repo.refreshPaymentStatus(id);
    } on PaymentFailure {
      // Non-fatal: the Firestore stream remains the source of truth.
    }
  }

  void _track(String paymentId) {
    _cancelTracking();
    _trackedPaymentId = paymentId;
    emit(
      state.copyWith(
        flow: BookingPaymentFlow.tracking,
        verifyingTooLong: false,
        clearFailure: true,
      ),
    );
    _slowTimer = Timer(slowAfter, () {
      if (isClosed || state.flow != BookingPaymentFlow.tracking) return;
      emit(state.copyWith(verifyingTooLong: true));
      unawaited(refresh());
    });
    _sub = _repo
        .watchPayment(paymentId)
        .listen(
          _onPayment,
          onError: (Object _) {
            if (isClosed) return;
            emit(
              state.copyWith(
                flow: BookingPaymentFlow.failed,
                failure: const PaymentFailure(PaymentFailureCode.unavailable),
              ),
            );
          },
        );
  }

  void _onPayment(BookingPayment? p) {
    if (isClosed || p == null) return;
    if (p.isPaidOnline) {
      _cancelTracking();
      emit(state.copyWith(flow: BookingPaymentFlow.succeeded, payment: p));
    } else if (p.isCashRecorded) {
      _cancelTracking();
      emit(state.copyWith(flow: BookingPaymentFlow.cashRecorded, payment: p));
    } else if (p.isTerminalFailure) {
      _cancelTracking();
      emit(state.copyWith(flow: BookingPaymentFlow.failed, payment: p));
    } else {
      emit(state.copyWith(flow: BookingPaymentFlow.tracking, payment: p));
    }
  }

  void _cancelTracking() {
    _slowTimer?.cancel();
    _slowTimer = null;
    _sub?.cancel();
    _sub = null;
  }

  @override
  Future<void> close() {
    _cancelTracking();
    return super.close();
  }
}
