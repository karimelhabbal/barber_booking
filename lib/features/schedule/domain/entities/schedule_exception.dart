import 'package:equatable/equatable.dart';

import 'weekly_schedule.dart';

class ScheduleException extends Equatable {
  final String id;
  final String barberId;
  final DateTime date;
  final bool isWorking;
  final String startTime;
  final String endTime;
  final List<ScheduleBreak> breaks;
  final String? reason;

  const ScheduleException({
    required this.id,
    required this.barberId,
    required this.date,
    required this.isWorking,
    required this.startTime,
    required this.endTime,
    required this.breaks,
    this.reason,
  });

  @override
  List<Object?> get props => [
    id,
    barberId,
    date,
    isWorking,
    startTime,
    endTime,
    breaks,
    reason,
  ];
}
