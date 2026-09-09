part of 'schedule_cubit.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded({required this.schedules});

  final List<WeeklySchedule> schedules;

  @override
  List<Object?> get props => [schedules];
}

class ScheduleSaving extends ScheduleState {
  const ScheduleSaving();
}

class ScheduleSaved extends ScheduleState {
  const ScheduleSaved({required this.schedules});

  final List<WeeklySchedule> schedules;

  @override
  List<Object?> get props => [schedules];
}

// -----------------------------------------------------------------------------
// Schedule Exceptions
// -----------------------------------------------------------------------------

class ScheduleExceptionsLoading extends ScheduleState {
  const ScheduleExceptionsLoading();
}

class ScheduleExceptionsLoaded extends ScheduleState {
  const ScheduleExceptionsLoaded({required this.exceptions});

  final List<ScheduleException> exceptions;

  @override
  List<Object?> get props => [exceptions];
}

class ScheduleExceptionCreating extends ScheduleState {
  const ScheduleExceptionCreating();
}

class ScheduleExceptionCreated extends ScheduleState {
  const ScheduleExceptionCreated({required this.exception});

  final ScheduleException exception;

  @override
  List<Object?> get props => [exception];
}

class ScheduleExceptionUpdating extends ScheduleState {
  const ScheduleExceptionUpdating();
}

class ScheduleExceptionUpdated extends ScheduleState {
  const ScheduleExceptionUpdated({required this.exception});

  final ScheduleException exception;

  @override
  List<Object?> get props => [exception];
}

class ScheduleExceptionDeleting extends ScheduleState {
  const ScheduleExceptionDeleting();
}

class ScheduleExceptionDeleted extends ScheduleState {
  const ScheduleExceptionDeleted({required this.exceptionId});

  final String exceptionId;

  @override
  List<Object?> get props => [exceptionId];
}

// -----------------------------------------------------------------------------
// Error
// -----------------------------------------------------------------------------

class ScheduleError extends ScheduleState {
  const ScheduleError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
