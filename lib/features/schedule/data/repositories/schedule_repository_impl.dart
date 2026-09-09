import '../../domain/entities/schedule_exception.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_data_source.dart';
import '../models/schedule_exception_model.dart';
import '../models/weekly_schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required this._remoteDataSource});

  final ScheduleRemoteDataSource _remoteDataSource;

  @override
  Future<List<WeeklySchedule>> getWeeklySchedule({required String barberId}) {
    return _remoteDataSource.getWeeklySchedule(barberId: barberId);
  }

  @override
  Future<WeeklySchedule> getDaySchedule({
    required String barberId,
    required int dayOfWeek,
  }) {
    return _remoteDataSource.getDaySchedule(
      barberId: barberId,
      dayOfWeek: dayOfWeek,
    );
  }

  @override
  Future<void> saveDaySchedule({required WeeklySchedule schedule}) {
    return _remoteDataSource.saveDaySchedule(
      schedule: WeeklyScheduleModel.fromEntity(schedule),
    );
  }

  @override
  Future<void> saveWeeklySchedule({required List<WeeklySchedule> schedules}) {
    return _remoteDataSource.saveWeeklySchedule(
      schedules: schedules.map(WeeklyScheduleModel.fromEntity).toList(),
    );
  }

  @override
  Future<List<ScheduleException>> getScheduleExceptions({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) {
    return _remoteDataSource.getScheduleExceptions(
      barberId: barberId,
      from: from,
      to: to,
    );
  }

  @override
  Future<ScheduleException> createScheduleException({
    required ScheduleException exception,
  }) {
    return _remoteDataSource.createScheduleException(
      exception: ScheduleExceptionModel.fromEntity(exception),
    );
  }

  @override
  Future<ScheduleException> updateScheduleException({
    required ScheduleException exception,
  }) {
    return _remoteDataSource.updateScheduleException(
      exception: ScheduleExceptionModel.fromEntity(exception),
    );
  }

  @override
  Future<void> deleteScheduleException({
    required String barberId,
    required String exceptionId,
  }) {
    return _remoteDataSource.deleteScheduleException(
      barberId: barberId,
      exceptionId: exceptionId,
    );
  }
}
