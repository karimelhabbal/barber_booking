import '../../../schedule/domain/entities/schedule_exception.dart';
import '../../../schedule/domain/entities/weekly_schedule.dart';
import '../../../schedule/domain/repositories/schedule_repository.dart';
import '../entities/available_slot.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/availability_service.dart';

class GetAvailableSlots {
  const GetAvailableSlots({
    required this._scheduleRepository,
    required this._bookingRepository,
    required this._availabilityService,
  });

  final ScheduleRepository _scheduleRepository;
  final BookingRepository _bookingRepository;
  final AvailabilityService _availabilityService;

  Future<List<AvailableSlot>> call({
    required String barberId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (serviceDurationMinutes <= 0) {
      throw ArgumentError('Service duration must be greater than zero.');
    }

    if (serviceDurationMinutes % 5 != 0) {
      throw ArgumentError('Service duration must be a multiple of 5 minutes.');
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);

    final dayOfWeek = normalizedDate.weekday;

    final results = await Future.wait([
      _scheduleRepository.getDaySchedule(
        barberId: trimmedBarberId,
        dayOfWeek: dayOfWeek,
      ),
      _scheduleRepository.getScheduleExceptions(
        barberId: trimmedBarberId,
        from: normalizedDate,
        to: normalizedDate,
      ),
      // Customer availability reads booked time ranges through the secure
      // `getBarberAvailability` Cloud Function instead of querying the
      // top-level bookings collection directly.
      _bookingRepository.getBookedTimeRangesForDate(
        barberId: trimmedBarberId,
        date: normalizedDate,
      ),
    ]);

    final weeklySchedule = results[0] as WeeklySchedule;

    final exceptions = results[1] as List<ScheduleException>;

    final bookings = results[2] as List<Booking>;

    ScheduleException? exception;

    if (exceptions.isNotEmpty) {
      exception = exceptions.first;
    }

    return _availabilityService.calculateAvailableSlots(
      date: normalizedDate,
      weeklySchedule: weeklySchedule,
      exception: exception,
      serviceDurationMinutes: serviceDurationMinutes,
      existingBookings: bookings,
    );
  }
}
