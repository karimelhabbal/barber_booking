import '../../domain/entities/weekly_schedule.dart';

class ScheduleBreakModel extends ScheduleBreak {
  const ScheduleBreakModel({required super.startTime, required super.endTime});

  factory ScheduleBreakModel.fromMap(Map<String, dynamic> data) {
    return ScheduleBreakModel(
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'startTime': startTime, 'endTime': endTime};
  }

  factory ScheduleBreakModel.fromEntity(ScheduleBreak breakItem) {
    return ScheduleBreakModel(
      startTime: breakItem.startTime,
      endTime: breakItem.endTime,
    );
  }
}

class WeeklyScheduleModel extends WeeklySchedule {
  const WeeklyScheduleModel({
    required super.barberId,
    required super.dayOfWeek,
    required super.isWorking,
    required super.startTime,
    required super.endTime,
    required super.breaks,
  });

  factory WeeklyScheduleModel.fromSupabaseJson(
    Map<String, dynamic> data, {
    required String barberId,
    required int dayOfWeek,
  }) {
    final rawBreaks = data['breaks'];
    final breaks = rawBreaks is List
        ? rawBreaks
              .whereType<Map>()
              .map(
                (item) =>
                    ScheduleBreakModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ScheduleBreakModel>[];

    return WeeklyScheduleModel(
      barberId: barberId,
      dayOfWeek: dayOfWeek,
      isWorking: data['isWorking'] as bool? ?? false,
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '17:00',
      breaks: breaks,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'isWorking': isWorking,
      'startTime': startTime,
      'endTime': endTime,
      'breaks': breaks
          .map((item) => ScheduleBreakModel.fromEntity(item).toMap())
          .toList(),
    };
  }

  factory WeeklyScheduleModel.fromEntity(WeeklySchedule schedule) {
    return WeeklyScheduleModel(
      barberId: schedule.barberId,
      dayOfWeek: schedule.dayOfWeek,
      isWorking: schedule.isWorking,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      breaks: schedule.breaks,
    );
  }
}

