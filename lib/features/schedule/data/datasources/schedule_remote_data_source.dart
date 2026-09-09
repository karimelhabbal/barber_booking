import 'package:cloud_firestore/cloud_firestore.dart';

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
  ScheduleRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _scheduleCollection(
    String barberId,
  ) {
    return _firestore
        .collection('barbers')
        .doc(barberId)
        .collection('weeklySchedule');
  }

  CollectionReference<Map<String, dynamic>> _exceptionsCollection(
    String barberId,
  ) {
    return _firestore
        .collection('barbers')
        .doc(barberId)
        .collection('scheduleExceptions');
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

    final snapshot = await _scheduleCollection(trimmedBarberId).get();

    final schedules = <WeeklyScheduleModel>[];

    for (final document in snapshot.docs) {
      final dayOfWeek = int.tryParse(document.id);

      if (dayOfWeek == null || dayOfWeek < 1 || dayOfWeek > 7) {
        continue;
      }

      schedules.add(
        WeeklyScheduleModel.fromFirestore(
          document,
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

    final document = await _scheduleCollection(trimmedBarberId)
        .doc(_dayId(dayOfWeek))
        .get();

    if (!document.exists) {
      return WeeklyScheduleModel(
        barberId: trimmedBarberId,
        dayOfWeek: dayOfWeek,
        isWorking: false,
        startTime: '09:00',
        endTime: '17:00',
        breaks: const [],
      );
    }

    return WeeklyScheduleModel.fromFirestore(
      document,
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

    await _scheduleCollection(barberId)
        .doc(_dayId(schedule.dayOfWeek))
        .set(schedule.toFirestore());
  }

  @override
  Future<void> saveWeeklySchedule({
    required List<WeeklyScheduleModel> schedules,
  }) async {
    if (schedules.isEmpty) {
      return;
    }

    final barberId = schedules.first.barberId.trim();

    if (barberId.isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    final batch = _firestore.batch();

    final collection = _scheduleCollection(barberId);

    for (final schedule in schedules) {
      if (schedule.barberId.trim() != barberId) {
        throw ArgumentError('All schedules must belong to the same barber.');
      }

      final reference = collection.doc(_dayId(schedule.dayOfWeek));

      batch.set(reference, schedule.toFirestore());
    }

    await batch.commit();
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

    final snapshot = await _exceptionsCollection(trimmedBarberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map(
          (document) => ScheduleExceptionModel.fromFirestore(
            document,
            barberId: trimmedBarberId,
          ),
        )
        .toList();
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

    final reference = _exceptionsCollection(barberId).doc(exceptionId);

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

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (snapshot.exists) {
        throw StateError(
          'A schedule exception already exists for '
          '${createdException.date.year}-'
          '${createdException.date.month.toString().padLeft(2, '0')}-'
          '${createdException.date.day.toString().padLeft(2, '0')}.',
        );
      }

      transaction.set(reference, createdException.toFirestore());
    });

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

    final oldReference = _exceptionsCollection(barberId).doc(oldExceptionId);

    final newReference = _exceptionsCollection(barberId).doc(newExceptionId);

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

    await _firestore.runTransaction((transaction) async {
      final oldSnapshot = await transaction.get(oldReference);

      if (!oldSnapshot.exists) {
        throw StateError('Schedule exception $oldExceptionId does not exist.');
      }

      if (oldExceptionId != newExceptionId) {
        final newSnapshot = await transaction.get(newReference);

        if (newSnapshot.exists) {
          throw StateError(
            'A schedule exception already exists for '
            '${updatedException.date.year}-'
            '${updatedException.date.month.toString().padLeft(2, '0')}-'
            '${updatedException.date.day.toString().padLeft(2, '0')}.',
          );
        }

        transaction.delete(oldReference);
      }

      transaction.set(newReference, updatedException.toFirestore());
    });

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

    await _exceptionsCollection(trimmedBarberId)
        .doc(trimmedExceptionId)
        .delete();
  }
}
