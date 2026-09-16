import '../../../schedule/domain/entities/schedule_exception.dart';
import '../../../schedule/domain/entities/weekly_schedule.dart';
import '../entities/available_slot.dart';
import '../entities/booking.dart';

class AvailabilityService {
  const AvailabilityService();

  List<AvailableSlot> calculateAvailableSlots({
    required DateTime date,
    required WeeklySchedule weeklySchedule,
    ScheduleException? exception,
    required int serviceDurationMinutes,
    required List<Booking> existingBookings,
  }) {
    if (serviceDurationMinutes <= 0) {
      throw ArgumentError('Service duration must be greater than zero.');
    }

    if (serviceDurationMinutes % 5 != 0) {
      throw ArgumentError('Service duration must be a multiple of 5 minutes.');
    }

    final effectiveSchedule = _resolveEffectiveSchedule(
      weeklySchedule: weeklySchedule,
      exception: exception,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isBefore(today)) {
      return const [];
    }

    if (!effectiveSchedule.isWorking) {
      return const [];
    }

    final workingStart = _combineDateAndTime(date, effectiveSchedule.startTime);

    final workingEnd = _combineDateAndTime(date, effectiveSchedule.endTime);

    if (!workingStart.isBefore(workingEnd)) {
      return const [];
    }

    final unavailableRanges = <_TimeRange>[
      ...effectiveSchedule.breaks.map(
        (breakItem) => _TimeRange(
          start: _combineDateAndTime(date, breakItem.startTime),
          end: _combineDateAndTime(date, breakItem.endTime),
        ),
      ),
      ...existingBookings
          .where((booking) => booking.status != BookingStatus.cancelled)
          .map(
            (booking) => _TimeRange(
              start: _combineDateAndTime(date, booking.startTime),
              end: _combineDateAndTime(date, booking.endTime),
            ),
          ),
    ];

    final normalizedUnavailableRanges = _normalizeRanges(
      unavailableRanges,
      workingStart: workingStart,
      workingEnd: workingEnd,
    );

    final slots = <AvailableSlot>[];

    final slotDuration = Duration(minutes: serviceDurationMinutes);

    var cursor = workingStart;

    if (_isSameDate(selectedDate, today)) {
      while (cursor.isBefore(now)) {
        cursor = cursor.add(const Duration(minutes: 5));
      }
    }

    while (cursor.add(slotDuration).isBefore(workingEnd) ||
        cursor.add(slotDuration).isAtSameMomentAs(workingEnd)) {
      final slotEnd = cursor.add(slotDuration);

      final overlapsUnavailable = normalizedUnavailableRanges.any(
        (range) => _overlaps(cursor, slotEnd, range.start, range.end),
      );

      if (!overlapsUnavailable) {
        slots.add(AvailableSlot(start: cursor, end: slotEnd));
      }

      cursor = cursor.add(const Duration(minutes: 5));
    }

    return slots;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  WeeklySchedule _resolveEffectiveSchedule({
    required WeeklySchedule weeklySchedule,
    ScheduleException? exception,
  }) {
    if (exception == null) {
      return weeklySchedule;
    }

    return WeeklySchedule(
      barberId: weeklySchedule.barberId,
      dayOfWeek: weeklySchedule.dayOfWeek,
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: exception.breaks,
    );
  }

  List<_TimeRange> _normalizeRanges(
    List<_TimeRange> ranges, {
    required DateTime workingStart,
    required DateTime workingEnd,
  }) {
    final clipped = <_TimeRange>[];

    for (final range in ranges) {
      if (!range.start.isBefore(range.end)) {
        continue;
      }

      if (!range.end.isAfter(workingStart) ||
          !range.start.isBefore(workingEnd)) {
        continue;
      }

      final start = range.start.isBefore(workingStart)
          ? workingStart
          : range.start;

      final end = range.end.isAfter(workingEnd) ? workingEnd : range.end;

      if (start.isBefore(end)) {
        clipped.add(_TimeRange(start: start, end: end));
      }
    }

    clipped.sort((a, b) => a.start.compareTo(b.start));

    final merged = <_TimeRange>[];

    for (final range in clipped) {
      if (merged.isEmpty) {
        merged.add(range);
        continue;
      }

      final previous = merged.last;

      if (!range.start.isAfter(previous.end)) {
        final mergedEnd = range.end.isAfter(previous.end)
            ? range.end
            : previous.end;

        merged[merged.length - 1] = _TimeRange(
          start: previous.start,
          end: mergedEnd,
        );
      } else {
        merged.add(range);
      }
    }

    return merged;
  }

  bool _overlaps(
    DateTime firstStart,
    DateTime firstEnd,
    DateTime secondStart,
    DateTime secondEnd,
  ) {
    return firstStart.isBefore(secondEnd) && firstEnd.isAfter(secondStart);
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      throw ArgumentError('Invalid time format: $time');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Invalid time value: $time');
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class _TimeRange {
  final DateTime start;
  final DateTime end;

  const _TimeRange({required this.start, required this.end});
}
