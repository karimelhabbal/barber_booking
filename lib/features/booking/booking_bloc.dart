import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<CreateBookingEvent>((e, emit) async {
      emit(BookingLoading());
      // TODO: implement Firestore write
      await Future.delayed(const Duration(milliseconds: 400));
      emit(BookingCreated());
    });

    on<LoadBookingsEvent>((e, emit) async {
      emit(BookingLoading());
      // TODO: load bookings from Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      emit(BookingLoaded(bookings: []));
    });
  }
}
