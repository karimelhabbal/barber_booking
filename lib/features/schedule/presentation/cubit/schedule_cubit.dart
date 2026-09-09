import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule_exception.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

part 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({required this._repository}) : super(const ScheduleInitial());

  final ScheduleRepository _repository;

  // ---------------------------------------------------------------------------
  // Weekly Schedule
  // ---------------------------------------------------------------------------

  Future<void> loadWeeklySchedule({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const ScheduleError('Barber ID cannot be empty.'));
      return;
    }

    emit(const ScheduleLoading());

    try {
      final schedules = await _repository.getWeeklySchedule(
        barberId: trimmedBarberId,
      );

      emit(
        ScheduleLoaded(
          schedules: _completeWeek(
            barberId: trimmedBarberId,
            schedules: schedules,
          ),
        ),
      );
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  Future<void> saveWeeklySchedule({
    required List<WeeklySchedule> schedules,
  }) async {
    final validationError = _validateWeeklySchedule(schedules);

    if (validationError != null) {
      emit(ScheduleError(validationError));
      return;
    }

    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    emit(const ScheduleSaving());

    try {
      await _repository.saveWeeklySchedule(schedules: sortedSchedules);

      emit(ScheduleSaved(schedules: sortedSchedules));
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Schedule Exceptions
  // ---------------------------------------------------------------------------

  Future<void> loadScheduleExceptions({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const ScheduleError('Barber ID cannot be empty.'));
      return;
    }

    if (from.isAfter(to)) {
      emit(const ScheduleError('From date cannot be after to date.'));
      return;
    }

    emit(const ScheduleExceptionsLoading());

    try {
      final exceptions = await _repository.getScheduleExceptions(
        barberId: trimmedBarberId,
        from: from,
        to: to,
      );

      emit(ScheduleExceptionsLoaded(exceptions: exceptions));
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  Future<void> createScheduleException({
    required String barberId,
    required DateTime date,
    required bool isWorking,
    required String startTime,
    required String endTime,
    required List<ScheduleBreak> breaks,
    String? reason,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const ScheduleError('Barber ID cannot be empty.'));
      return;
    }

    final validationError = _validateExceptionData(
      date: date,
      isWorking: isWorking,
      startTime: startTime,
      endTime: endTime,
      breaks: breaks,
    );

    if (validationError != null) {
      emit(ScheduleError(validationError));
      return;
    }

    final trimmedReason = reason?.trim();

    final exception = ScheduleException(
      id: '',
      barberId: trimmedBarberId,
      date: _dateOnly(date),
      isWorking: isWorking,
      startTime: startTime,
      endTime: endTime,
      breaks: List.unmodifiable(breaks),
      reason: trimmedReason?.isEmpty == true ? null : trimmedReason,
    );

    emit(const ScheduleExceptionCreating());

    try {
      final createdException = await _repository.createScheduleException(
        exception: exception,
      );

      emit(ScheduleExceptionCreated(exception: createdException));
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  Future<void> updateScheduleException({
    required ScheduleException exception,
  }) async {
    if (exception.id.trim().isEmpty) {
      emit(const ScheduleError('Schedule exception ID cannot be empty.'));
      return;
    }

    if (exception.barberId.trim().isEmpty) {
      emit(const ScheduleError('Barber ID cannot be empty.'));
      return;
    }

    final validationError = _validateExceptionData(
      date: exception.date,
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: exception.breaks,
    );

    if (validationError != null) {
      emit(ScheduleError(validationError));
      return;
    }

    final normalizedException = ScheduleException(
      id: exception.id.trim(),
      barberId: exception.barberId.trim(),
      date: _dateOnly(exception.date),
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: List.unmodifiable(exception.breaks),
      reason: exception.reason?.trim().isEmpty == true
          ? null
          : exception.reason?.trim(),
    );

    emit(const ScheduleExceptionUpdating());

    try {
      final updatedException = await _repository.updateScheduleException(
        exception: normalizedException,
      );

      emit(ScheduleExceptionUpdated(exception: updatedException));
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  Future<void> deleteScheduleException({
    required String barberId,
    required String exceptionId,
  }) async {
    final trimmedBarberId = barberId.trim();
    final trimmedExceptionId = exceptionId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const ScheduleError('Barber ID cannot be empty.'));
      return;
    }

    if (trimmedExceptionId.isEmpty) {
      emit(const ScheduleError('Schedule exception ID cannot be empty.'));
      return;
    }

    emit(const ScheduleExceptionDeleting());

    try {
      await _repository.deleteScheduleException(
        barberId: trimmedBarberId,
        exceptionId: trimmedExceptionId,
      );

      emit(ScheduleExceptionDeleted(exceptionId: trimmedExceptionId));
    } on Object catch (error) {
      emit(ScheduleError(error.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Weekly Schedule Validation
  // ---------------------------------------------------------------------------

  String? _validateWeeklySchedule(List<WeeklySchedule> schedules) {
    if (schedules.isEmpty) {
      return 'Schedule cannot be empty.';
    }

    final barberId = schedules.first.barberId.trim();

    if (barberId.isEmpty) {
      return 'Barber ID cannot be empty.';
    }

    if (schedules.length != 7) {
      return 'Weekly schedule must contain 7 days.';
    }

    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    for (var index = 0; index < sortedSchedules.length; index++) {
      final schedule = sortedSchedules[index];

      if (schedule.barberId.trim() != barberId) {
        return 'All schedule days must belong to the same barber.';
      }

      final expectedDay = index + 1;

      if (schedule.dayOfWeek != expectedDay) {
        return 'Weekly schedule must contain days 1 through 7.';
      }

      if (!_isValidTime(schedule.startTime) ||
          !_isValidTime(schedule.endTime)) {
        return 'Invalid working time for day '
            '${schedule.dayOfWeek}.';
      }

      if (schedule.isWorking &&
          !_isBefore(schedule.startTime, schedule.endTime)) {
        return 'Start time must be before end time '
            'for day ${schedule.dayOfWeek}.';
      }

      final breakValidationError = _validateBreaks(
        breaks: schedule.breaks,
        isWorking: schedule.isWorking,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        dayLabel: 'day ${schedule.dayOfWeek}',
      );

      if (breakValidationError != null) {
        return breakValidationError;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Exception Validation
  // ---------------------------------------------------------------------------

  String? _validateExceptionData({
    required DateTime date,
    required bool isWorking,
    required String startTime,
    required String endTime,
    required List<ScheduleBreak> breaks,
  }) {
    if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
      return 'Invalid working time.';
    }

    if (isWorking && !_isBefore(startTime, endTime)) {
      return 'Start time must be before end time.';
    }

    return _validateBreaks(
      breaks: breaks,
      isWorking: isWorking,
      startTime: startTime,
      endTime: endTime,
      dayLabel: 'this date',
    );
  }

  String? _validateBreaks({
    required List<ScheduleBreak> breaks,
    required bool isWorking,
    required String startTime,
    required String endTime,
    required String dayLabel,
  }) {
    for (final breakItem in breaks) {
      if (!_isValidTime(breakItem.startTime) ||
          !_isValidTime(breakItem.endTime)) {
        return 'Invalid break time for $dayLabel.';
      }

      if (!_isBefore(breakItem.startTime, breakItem.endTime)) {
        return 'Break start time must be before break end time '
            'for $dayLabel.';
      }

      if (!isWorking) {
        return 'A day off cannot contain breaks for '
            '$dayLabel.';
      }

      if (!_isAtOrAfter(breakItem.startTime, startTime) ||
          !_isAtOrBefore(breakItem.endTime, endTime)) {
        return 'Break must be inside working hours for '
            '$dayLabel.';
      }
    }

    final sortedBreaks = [...breaks]
      ..sort(
        (a, b) =>
            _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
      );

    for (var i = 1; i < sortedBreaks.length; i++) {
      final previous = sortedBreaks[i - 1];
      final current = sortedBreaks[i];

      if (_timeToMinutes(current.startTime) <
          _timeToMinutes(previous.endTime)) {
        return 'Breaks cannot overlap on $dayLabel.';
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<WeeklySchedule> _completeWeek({
    required String barberId,
    required List<WeeklySchedule> schedules,
  }) {
    final existing = <int, WeeklySchedule>{
      for (final schedule in schedules) schedule.dayOfWeek: schedule,
    };

    return List.generate(7, (index) {
      final dayOfWeek = index + 1;

      return existing[dayOfWeek] ??
          WeeklySchedule(
            barberId: barberId,
            dayOfWeek: dayOfWeek,
            isWorking: false,
            startTime: '09:00',
            endTime: '17:00',
            breaks: const [],
          );
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isValidTime(String value) {
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _isBefore(String first, String second) {
    return _timeToMinutes(first) < _timeToMinutes(second);
  }

  bool _isAtOrAfter(String first, String second) {
    return _timeToMinutes(first) >= _timeToMinutes(second);
  }

  bool _isAtOrBefore(String first, String second) {
    return _timeToMinutes(first) <= _timeToMinutes(second);
  }
}
