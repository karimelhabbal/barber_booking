import '../entities/schedule_exception.dart';
import '../entities/weekly_schedule.dart';

abstract interface class ScheduleRepository {
  Future<List<WeeklySchedule>> getWeeklySchedule({required String barberId});

  Future<WeeklySchedule> getDaySchedule({
    required String barberId,
    required int dayOfWeek,
  });

  Future<void> saveDaySchedule({required WeeklySchedule schedule});

  Future<void> saveWeeklySchedule({required List<WeeklySchedule> schedules});

  Future<List<ScheduleException>> getScheduleExceptions({
    required String barberId,
    required DateTime from,
    required DateTime to,
  });

  Future<ScheduleException> createScheduleException({
    required ScheduleException exception,
  });

  Future<ScheduleException> updateScheduleException({
    required ScheduleException exception,
  });

  Future<void> deleteScheduleException({
    required String barberId,
    required String exceptionId,
  });
}
