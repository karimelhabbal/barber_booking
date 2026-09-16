import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

abstract interface class BookingRemoteDataSource {
  Future<List<BookingModel>> getBarberBookingsForDate({
    required String barberId,
    required DateTime date,
  });

  Future<List<BookingModel>> getCustomerBookings({required String customerId});

  Future<List<BookingModel>> getOwnerBookings({required String shopId});

  Future<List<BookingModel>> getBarberBookings({required String barberId});

  Future<BookingModel?> getBooking({required String bookingId});

  Future<BookingModel> createBooking({required BookingModel booking});

  Future<void> cancelBooking({required String bookingId});

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> _bookingLocksCollection(
    String barberId,
  ) {
    return _firestore
        .collection('barbers')
        .doc(barberId)
        .collection('bookingLocks');
  }

  @override
  Future<List<BookingModel>> getBarberBookingsForDate({
    required String barberId,
    required DateTime date,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final startOfDay = DateTime(date.year, date.month, date.day);

    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _bookingsCollection
        .where('barberId', isEqualTo: trimmedBarberId)
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('bookingDate', isLessThan: Timestamp.fromDate(startOfNextDay))
        .get();

    return snapshot.docs
        .map(BookingModel.fromFirestore)
        .where((booking) => booking.status != BookingStatus.cancelled)
        .toList();
  }

  @override
  Future<List<BookingModel>> getCustomerBookings({
    required String customerId,
  }) async {
    final trimmedCustomerId = customerId.trim();

    if (trimmedCustomerId.isEmpty) {
      throw ArgumentError('Customer ID cannot be empty.');
    }

    final snapshot = await _bookingsCollection
        .where('customerId', isEqualTo: trimmedCustomerId)
        .orderBy('bookingDate', descending: true)
        .get();

    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  @override
  Future<List<BookingModel>> getOwnerBookings({required String shopId}) async {
    final trimmedShopId = shopId.trim();

    if (trimmedShopId.isEmpty) {
      throw ArgumentError('Barber shop ID cannot be empty.');
    }

    final snapshot = await _bookingsCollection
        .where('shopId', isEqualTo: trimmedShopId)
        .orderBy('bookingDate', descending: true)
        .get();

    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  @override
  Future<List<BookingModel>> getBarberBookings({
    required String barberId,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final snapshot = await _bookingsCollection
        .where('barberId', isEqualTo: trimmedBarberId)
        .orderBy('bookingDate', descending: true)
        .get();

    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  @override
  Future<BookingModel?> getBooking({required String bookingId}) async {
    final trimmedBookingId = bookingId.trim();

    if (trimmedBookingId.isEmpty) {
      throw ArgumentError('Booking ID cannot be empty.');
    }

    final document = await _bookingsCollection.doc(trimmedBookingId).get();

    if (!document.exists) {
      return null;
    }

    return BookingModel.fromFirestore(document);
  }

  @override
  Future<BookingModel> createBooking({required BookingModel booking}) async {
    _validateBooking(booking);

    final customerId = booking.customerId.trim();
    final shopId = booking.shopId.trim();
    final barberId = booking.barberId.trim();
    final serviceId = booking.serviceId.trim();

    final normalizedDate = DateTime(
      booking.bookingDate.year,
      booking.bookingDate.month,
      booking.bookingDate.day,
    );

    final startMinutes = _timeToMinutes(booking.startTime);

    final endMinutes = _timeToMinutes(booking.endTime);

    if (endMinutes <= startMinutes) {
      throw ArgumentError('Booking end time must be after start time.');
    }

    final actualDuration = endMinutes - startMinutes;

    if (actualDuration != booking.serviceDurationMinutes) {
      throw ArgumentError('Booking duration does not match service duration.');
    }

    final bookingReference = _bookingsCollection.doc();

    final now = DateTime.now();

    final createdBooking = BookingModel(
      id: bookingReference.id,
      customerId: customerId,
      shopId: shopId,
      barberId: barberId,
      serviceId: serviceId,
      bookingDate: normalizedDate,
      startTime: booking.startTime,
      endTime: booking.endTime,

      // A newly created booking starts as pending.
      // Barber/owner can confirm it later.
      status: BookingStatus.pending,

      serviceName: booking.serviceName.trim(),
      serviceDurationMinutes: booking.serviceDurationMinutes,
      servicePrice: booking.servicePrice,
      customerName: booking.customerName.trim(),
      barberName: booking.barberName.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final lockReferences = <DocumentReference<Map<String, dynamic>>>[];

    for (var minutes = startMinutes; minutes < endMinutes; minutes += 5) {
      final lockId = _buildLockId(
        date: normalizedDate,
        minutesFromMidnight: minutes,
      );

      lockReferences.add(_bookingLocksCollection(barberId).doc(lockId));
    }

    await _firestore.runTransaction((transaction) async {
      final lockSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

      // All reads must happen before writes in a Firestore
      // transaction.
      for (final lockReference in lockReferences) {
        final snapshot = await transaction.get(lockReference);

        lockSnapshots.add(snapshot);
      }

      for (final snapshot in lockSnapshots) {
        if (snapshot.exists) {
          throw StateError('The selected time slot is no longer available.');
        }
      }

      transaction.set(bookingReference, createdBooking.toFirestore());

      for (var index = 0; index < lockReferences.length; index++) {
        final lockReference = lockReferences[index];

        final minutes = startMinutes + (index * 5);

        transaction.set(lockReference, {
          'bookingId': createdBooking.id,
          'customerId': createdBooking.customerId,
          'shopId': createdBooking.shopId,
          'barberId': createdBooking.barberId,
          'date': Timestamp.fromDate(normalizedDate),
          'startTime': _minutesToTime(minutes),
          'endTime': _minutesToTime(minutes + 5),
          'createdAt': Timestamp.fromDate(now),
        });
      }
    });

    return createdBooking;
  }

  @override
  Future<void> cancelBooking({required String bookingId}) async {
    final trimmedBookingId = bookingId.trim();

    if (trimmedBookingId.isEmpty) {
      throw ArgumentError('Booking ID cannot be empty.');
    }

    final bookingReference = _bookingsCollection.doc(trimmedBookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingReference);

      if (!bookingSnapshot.exists) {
        throw StateError('Booking $trimmedBookingId does not exist.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.status == BookingStatus.cancelled) {
        return;
      }

      final startMinutes = _timeToMinutes(booking.startTime);

      final endMinutes = _timeToMinutes(booking.endTime);

      final lockReferences = <DocumentReference<Map<String, dynamic>>>[];

      for (var minutes = startMinutes; minutes < endMinutes; minutes += 5) {
        final lockId = _buildLockId(
          date: booking.bookingDate,
          minutesFromMidnight: minutes,
        );

        lockReferences.add(
          _bookingLocksCollection(booking.barberId).doc(lockId),
        );
      }

      final lockSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final lockReference in lockReferences) {
        final snapshot = await transaction.get(lockReference);

        lockSnapshots.add(snapshot);
      }

      transaction.update(bookingReference, {
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      for (var index = 0; index < lockReferences.length; index++) {
        final snapshot = lockSnapshots[index];

        if (!snapshot.exists) {
          continue;
        }

        final data = snapshot.data();

        if (data == null) {
          continue;
        }

        if (data['bookingId'] == booking.id) {
          transaction.delete(lockReferences[index]);
        }
      }
    });
  }

  @override
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final trimmedBookingId = bookingId.trim();

    if (trimmedBookingId.isEmpty) {
      throw ArgumentError('Booking ID cannot be empty.');
    }

    final bookingReference = _bookingsCollection.doc(trimmedBookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingReference);

      if (!bookingSnapshot.exists) {
        throw StateError('Booking $trimmedBookingId does not exist.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      final isAllowed = switch (booking.status) {
        BookingStatus.pending => status == BookingStatus.confirmed,
        BookingStatus.confirmed =>
          status == BookingStatus.completed || status == BookingStatus.noShow,
        _ => false,
      };

      if (!isAllowed) {
        throw StateError('Booking status transition is not allowed.');
      }

      transaction.update(bookingReference, {
        'status': BookingModel.statusToFirestore(status),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  void _validateBooking(BookingModel booking) {
    if (booking.customerId.trim().isEmpty) {
      throw ArgumentError('Customer ID cannot be empty.');
    }

    if (booking.shopId.trim().isEmpty) {
      throw ArgumentError('Shop ID cannot be empty.');
    }

    if (booking.barberId.trim().isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (booking.serviceId.trim().isEmpty) {
      throw ArgumentError('Service ID cannot be empty.');
    }

    if (booking.serviceName.trim().isEmpty) {
      throw ArgumentError('Service name cannot be empty.');
    }

    if (booking.customerName.trim().isEmpty) {
      throw ArgumentError('Customer name cannot be empty.');
    }

    if (booking.barberName.trim().isEmpty) {
      throw ArgumentError('Barber name cannot be empty.');
    }

    if (booking.serviceDurationMinutes <= 0) {
      throw ArgumentError('Service duration must be greater than zero.');
    }

    if (booking.serviceDurationMinutes % 5 != 0) {
      throw ArgumentError('Service duration must be a multiple of 5 minutes.');
    }

    if (booking.servicePrice < 0) {
      throw ArgumentError('Service price cannot be negative.');
    }

    if (!_isValidTime(booking.startTime)) {
      throw ArgumentError('Invalid booking start time.');
    }

    if (!_isValidTime(booking.endTime)) {
      throw ArgumentError('Invalid booking end time.');
    }

    final startMinutes = _timeToMinutes(booking.startTime);

    final endMinutes = _timeToMinutes(booking.endTime);

    if (startMinutes % 5 != 0) {
      throw ArgumentError('Booking start time must be on a 5-minute interval.');
    }

    if (endMinutes <= startMinutes) {
      throw ArgumentError('Booking end time must be after start time.');
    }

    final actualDuration = endMinutes - startMinutes;

    if (actualDuration != booking.serviceDurationMinutes) {
      throw ArgumentError('Booking duration does not match service duration.');
    }
  }

  String _buildLockId({
    required DateTime date,
    required int minutesFromMidnight,
  }) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    final hour = (minutesFromMidnight ~/ 60).toString().padLeft(2, '0');

    final minute = (minutesFromMidnight % 60).toString().padLeft(2, '0');

    return '$year-$month-${day}_'
        '$hour-$minute';
  }

  bool _isValidTime(String value) {
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      throw ArgumentError('Invalid time format: $value');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Invalid time value: $value');
    }

    return (hour * 60) + minute;
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
