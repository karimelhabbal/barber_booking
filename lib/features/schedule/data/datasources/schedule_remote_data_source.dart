import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_exception_model.dart';
import '../models/weekly_schedule_model.dart';

abstract interface class ScheduleRemoteDataSource {
  Future<List<WeeklyScheduleModel>> getWeeklySchedule({
    required String barberId,
  });

  Future<WeeklyScheduleModel> getDaySchedule({
    required String barberId,
    required int dayOfWeek,
  });

  Future<void> saveDaySchedule({required WeeklyScheduleModel schedule});

  Future<void> saveWeeklySchedule({
    required List<WeeklyScheduleModel> schedules,
  });

  Future<List<ScheduleExceptionModel>> getScheduleExceptions({
    required String barberId,
    required DateTime from,
    required DateTime to,
  });

  Future<ScheduleExceptionModel> createScheduleException({
    required ScheduleExceptionModel exception,
  });

  Future<ScheduleExceptionModel> updateScheduleException({
    required ScheduleExceptionModel exception,
  });

  Future<void> deleteScheduleException({
    required String barberId,
    required String exceptionId,
  });
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  ScheduleRemoteDataSourceImpl({required this._supabase});

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> _weeklySchedule(String barberId) async {
    final row = await _supabase
        .from('barbers')
        .select('weekly_schedule')
        .eq('id', barberId)
        .maybeSingle();
    if (row == null) throw StateError('Barber $barberId does not exist.');
    final value = row['weekly_schedule'];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  Future<void> _saveWeeklySchedule(
    String barberId,
    Map<String, dynamic> schedule,
  ) async {
    await _supabase
        .from('barbers')
        .update({
          'weekly_schedule': schedule,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', barberId);
  }

  String _dayId(int dayOfWeek) {
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      throw ArgumentError('dayOfWeek must be between 1 and 7.');
    }

    return dayOfWeek.toString();
  }

  @override
  Future<List<WeeklyScheduleModel>> getWeeklySchedule({
    required String barberId,
  }) async {
    final trimmedBarberId = barberId.trim();
    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }
    final storedSchedule = await _weeklySchedule(trimmedBarberId);
    final schedules = <WeeklyScheduleModel>[];
    for (final entry in storedSchedule.entries) {
      final dayOfWeek = int.tryParse(entry.key);
      if (dayOfWeek == null ||
          dayOfWeek < 1 ||
          dayOfWeek > 7 ||
          entry.value is! Map) {
        continue;
      }
      schedules.add(
        WeeklyScheduleModel.fromSupabaseJson(
          Map<String, dynamic>.from(entry.value as Map),
          barberId: trimmedBarberId,
          dayOfWeek: dayOfWeek,
        ),
      );
    }
    schedules.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    return schedules;
  }

  @override
  Future<WeeklyScheduleModel> getDaySchedule({
    required String barberId,
    required int dayOfWeek,
  }) async {
    final trimmedBarberId = barberId.trim();
    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }
    final storedSchedule = await _weeklySchedule(trimmedBarberId);
    final daySchedule = storedSchedule[_dayId(dayOfWeek)];
    if (daySchedule is! Map) {
      return WeeklyScheduleModel(
        barberId: trimmedBarberId,
        dayOfWeek: dayOfWeek,
        isWorking: false,
        startTime: '09:00',
        endTime: '17:00',
        breaks: const [],
      );
    }
    return WeeklyScheduleModel.fromSupabaseJson(
      Map<String, dynamic>.from(daySchedule),
      barberId: trimmedBarberId,
      dayOfWeek: dayOfWeek,
    );
  }

  @override
  Future<void> saveDaySchedule({required WeeklyScheduleModel schedule}) async {
    final barberId = schedule.barberId.trim();

    if (barberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final storedSchedule = await _weeklySchedule(barberId);
    storedSchedule[_dayId(schedule.dayOfWeek)] = schedule.toSupabaseJson();
    await _saveWeeklySchedule(barberId, storedSchedule);
  }

  @override
  Future<void> saveWeeklySchedule({
    required List<WeeklyScheduleModel> schedules,
  }) async {
    if (schedules.isEmpty) return;
    final barberId = schedules.first.barberId.trim();
    if (barberId.isEmpty) throw ArgumentError('Barber ID cannot be empty.');
    final storedSchedule = await _weeklySchedule(barberId);
    for (final schedule in schedules) {
      if (schedule.barberId.trim() != barberId) {
        throw ArgumentError('All schedules must belong to the same barber.');
      }
      storedSchedule[_dayId(schedule.dayOfWeek)] = schedule.toSupabaseJson();
    }
    await _saveWeeklySchedule(barberId, storedSchedule);
  }

  @override
  Future<List<ScheduleExceptionModel>> getScheduleExceptions({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (from.isAfter(to)) {
      throw ArgumentError('From date cannot be after to date.');
    }

    final rows = await _supabase
        .from('schedule_exceptions')
        .select()
        .eq('barber_id', trimmedBarberId)
        .gte('date', _exceptionIdForDate(from))
        .lte('date', _exceptionIdForDate(to))
        .order('date', ascending: true);

    return rows.map(ScheduleExceptionModel.fromSupabaseJson).toList();
  }

  String _exceptionIdForDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Future<ScheduleExceptionModel> createScheduleException({
    required ScheduleExceptionModel exception,
  }) async {
    final barberId = exception.barberId.trim();

    if (barberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final exceptionId = _exceptionIdForDate(exception.date);

    final createdException = ScheduleExceptionModel(
      id: exceptionId,
      barberId: barberId,
      date: DateTime(
        exception.date.year,
        exception.date.month,
        exception.date.day,
      ),
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: exception.breaks,
      reason: exception.reason?.trim(),
    );

    final existing = await _supabase
        .from('schedule_exceptions')
        .select('id')
        .eq('barber_id', barberId)
        .eq('id', exceptionId)
        .maybeSingle();

    if (existing != null) {
      throw StateError(
        'A schedule exception already exists for '
        '${createdException.date.year}-'
        '${createdException.date.month.toString().padLeft(2, '0')}-'
        '${createdException.date.day.toString().padLeft(2, '0')}.',
      );
    }

    await _supabase
        .from('schedule_exceptions')
        .insert(createdException.toSupabaseJson());

    return createdException;
  }

  @override
  Future<ScheduleExceptionModel> updateScheduleException({
    required ScheduleExceptionModel exception,
  }) async {
    final barberId = exception.barberId.trim();
    final oldExceptionId = exception.id.trim();

    if (barberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (oldExceptionId.isEmpty) {
      throw ArgumentError('Schedule exception ID cannot be empty.');
    }

    final newExceptionId = _exceptionIdForDate(exception.date);

    final updatedException = ScheduleExceptionModel(
      id: newExceptionId,
      barberId: barberId,
      date: DateTime(
        exception.date.year,
        exception.date.month,
        exception.date.day,
      ),
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: exception.breaks,
      reason: exception.reason?.trim(),
    );

    final existing = await _supabase
        .from('schedule_exceptions')
        .select('id')
        .eq('barber_id', barberId)
        .eq('id', oldExceptionId)
        .maybeSingle();

    if (existing == null) {
      throw StateError('Schedule exception $oldExceptionId does not exist.');
    }

    if (oldExceptionId != newExceptionId) {
      final conflict = await _supabase
          .from('schedule_exceptions')
          .select('id')
          .eq('barber_id', barberId)
          .eq('id', newExceptionId)
          .maybeSingle();

      if (conflict != null) {
        throw StateError(
          'A schedule exception already exists for '
          '${updatedException.date.year}-'
          '${updatedException.date.month.toString().padLeft(2, '0')}-'
          '${updatedException.date.day.toString().padLeft(2, '0')}.',
        );
      }
    }

    await _supabase
        .from('schedule_exceptions')
        .update(updatedException.toSupabaseJson())
        .eq('barber_id', barberId)
        .eq('id', oldExceptionId);

    return updatedException;
  }

  @override
  Future<void> deleteScheduleException({
    required String barberId,
    required String exceptionId,
  }) async {
    final trimmedBarberId = barberId.trim();
    final trimmedExceptionId = exceptionId.trim();

    if (trimmedBarberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (trimmedExceptionId.isEmpty) {
      throw ArgumentError('Schedule exception ID cannot be empty.');
    }

    await _supabase
        .from('schedule_exceptions')
        .delete()
        .eq('barber_id', trimmedBarberId)
        .eq('id', trimmedExceptionId);
  }
}
