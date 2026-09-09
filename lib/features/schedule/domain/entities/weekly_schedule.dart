import 'package:equatable/equatable.dart';

class ScheduleBreak extends Equatable {
  final String startTime;
  final String endTime;

  const ScheduleBreak({required this.startTime, required this.endTime});

  @override
  List<Object?> get props => [startTime, endTime];
}

class WeeklySchedule extends Equatable {
  final String barberId;
  final int dayOfWeek;
  final bool isWorking;
  final String startTime;
  final String endTime;
  final List<ScheduleBreak> breaks;

  const WeeklySchedule({
    required this.barberId,
    required this.dayOfWeek,
    required this.isWorking,
    required this.startTime,
    required this.endTime,
    required this.breaks,
  });

  @override
  List<Object?> get props => [
    barberId,
    dayOfWeek,
    isWorking,
    startTime,
    endTime,
    breaks,
  ];
}
